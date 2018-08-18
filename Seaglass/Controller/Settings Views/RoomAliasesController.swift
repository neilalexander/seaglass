//
// Seaglass, a native macOS Matrix client
// Copyright © 2018, Neil Alexander
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Cocoa

class RoomAliasesController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var AliasTable: NSTableView!
    @IBOutlet var AliasSave: NSButton!
    @IBOutlet var AliasCancel: NSButton!
    @IBOutlet var AliasAdd: NSButton!
    @IBOutlet var StatusSpinner: NSProgressIndicator!
    
    var canonicalRoomAlias: String = ""
    var roomAliases: [RoomAliasEntry] = []
    var roomId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if roomId != "" {
            let room = MatrixServices.inst.session.room(withRoomId: roomId)
            let suffix = MatrixServices.inst.client.homeserverSuffix ?? ":matrix.org"
            let aliases = room!.state.aliases
            if aliases == nil {
                return
            }
            if aliases!.count == 0 {
                return
            }
            for alias in aliases! {
                let cell = AliasTable.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomAliasEntry"), owner: self) as? RoomAliasEntry
                cell?.parent = self
                cell?.RoomAliasName.stringValue = alias
                cell?.RoomAliasName.placeholderString = "#youralias\(suffix)"
                cell?.RoomAliasPrimary.isEnabled = { () -> Bool in
                    let aliasPowerLevel = { () -> Int in
                        if room!.state.powerLevels.events.contains(where: { (arg) -> Bool in arg.key as! String == "m.room.canonical_alias" }) {
                            return room!.state.powerLevels.events["m.room.canonical_alias"] as! Int
                        }
                        return 50
                    }()
                    return room!.state.powerLevels.powerLevelOfUser(withUserID: MatrixServices.inst.session.myUser.userId) >= aliasPowerLevel
                }()
                cell?.RoomAliasPrimary.state = room!.state.canonicalAlias == alias ? .on : .off
                cell?.RoomAliasName.isEnabled = alias.hasSuffix(suffix)
                cell?.RoomAliasDelete.isEnabled = alias.hasSuffix(suffix)
                roomAliases.append(cell!)
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return roomAliases.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return roomAliases[row]
    }
    
    func primaryButtonClicked(sender: RoomAliasEntry) {
        for alias in roomAliases {
            if alias != sender {
                alias.RoomAliasPrimary.state = .off
            }
        }
    }
    
    func deleteButtonClicked(sender: RoomAliasEntry) {
        let index = roomAliases.index(of: sender)
        roomAliases.remove(at: index!)
        AliasTable.removeRows(at: IndexSet(integer: index!), withAnimation: [ .slideUp, .effectFade ])
        AliasTable.noteNumberOfRowsChanged()
    }
    
    @IBAction func addButtonClicked(_ sender: NSButton) {
        if sender != AliasAdd {
            return
        }
    
        let suffix = MatrixServices.inst.client.homeserverSuffix ?? ":matrix.org"
        let cell = AliasTable.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomAliasEntry"), owner: self) as? RoomAliasEntry
        cell?.parent = self
        cell?.RoomAliasName.placeholderString = "#youralias\(suffix)"
        roomAliases.append(cell!)
        AliasTable.noteNumberOfRowsChanged()
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        if sender != AliasSave {
            return
        }
        
        StatusSpinner.isHidden = false
        StatusSpinner.startAnimation(self)
        for button in [ AliasSave, AliasCancel, AliasAdd ] {
            button!.isEnabled = false
        }
        
        let group = DispatchGroup()
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        let suffix = MatrixServices.inst.client.homeserverSuffix ?? ":matrix.org"
        let aliases = room!.state.aliases != nil ? room!.state.aliases : []
        
        var uiCanonicalAlias: String = ""
        var uiAliases: [String] = []
        
        for uiAlias in roomAliases {
            uiAliases.append(uiAlias.RoomAliasName.stringValue)
            if uiAlias.RoomAliasPrimary.state == .on {
                uiCanonicalAlias = uiAlias.RoomAliasName.stringValue
            }
        }
        
        for uiAlias in uiAliases {
            if !uiAlias.hasSuffix(suffix) {
                continue
            }
            if !aliases!.contains(uiAlias) {
                group.enter()
                room?.addAlias(uiAlias, completion: { (response) in
                    if response.isFailure {
                        let alert = NSAlert()
                        alert.messageText = "Failed to add alias \(uiAlias)"
                        alert.informativeText = response.error!.localizedDescription
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                    group.leave()
                })
            }
        }
        
        for alias in aliases! {
            if !alias.hasSuffix(suffix) {
                continue
            }
            if !uiAliases.contains(alias) {
                group.enter()
                room?.removeAlias(alias, completion: { (response) in
                    if response.isFailure {
                        let alert = NSAlert()
                        alert.messageText = "Failed to remove alias \(alias)"
                        alert.informativeText = response.error!.localizedDescription
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                    group.leave()
                })
            }
        }
        
        if uiCanonicalAlias != room?.state.canonicalAlias {
            group.enter()
            room?.setCanonicalAlias(uiCanonicalAlias, completion: { (response) in
                if response.isFailure {
                    let alert = NSAlert()
                    alert.messageText = "Failed to set primary alias to \(uiCanonicalAlias)"
                    alert.informativeText = response.error!.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main, execute: {
            self.StatusSpinner.isHidden = true
            self.StatusSpinner.stopAnimation(self)
            for button in [ self.AliasSave, self.AliasCancel, self.AliasAdd ] {
                button!.isEnabled = true
            }
            sender.window?.contentViewController?.dismiss(sender)
        })
    }
    
}
