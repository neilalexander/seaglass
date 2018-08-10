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
                cell?.RoomAliasPrimary.state = room!.state.canonicalAlias == alias ? .on : .off
                if !alias.hasSuffix(suffix) {
                    cell?.RoomAliasName.isEnabled = false
                    cell?.RoomAliasDelete.isEnabled = false
                }
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
        print("Delete button clicked")
        
        let index = roomAliases.index(of: sender)
        roomAliases.remove(at: index!)
        AliasTable.removeRows(at: IndexSet.init(integer: index!), withAnimation: [ .slideUp, .effectFade ])
        AliasTable.noteNumberOfRowsChanged()
    }
    
    @IBAction func addButtonClicked(_ sender: NSButton) {
        if sender != AliasAdd {
            return
        }
        print("Add button clicked")
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
        print("Save button clicked")
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
                room?.addAlias(uiAlias, completion: { (response) in
                    if response.isFailure {
                        print("Failed to add new alias \(uiAlias)")
                    }
                })
            }
        }
        
        for alias in aliases! {
            if !alias.hasSuffix(suffix) {
                continue
            }
            if !uiAliases.contains(alias) {
                room?.removeAlias(alias, completion: { (response) in
                    if response.isFailure {
                        print("Failed to remove alias \(alias)")
                    }
                })
            }
        }
        
        if uiCanonicalAlias != room?.state.canonicalAlias {
            room?.setCanonicalAlias(uiCanonicalAlias, completion: { (response) in
                if response.isFailure {
                    print("Failed to set canonical alias \(uiCanonicalAlias)")
                }
            })
        }
        
        sender.window?.close()
    }
    
}
