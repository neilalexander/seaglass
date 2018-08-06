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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if roomId != "" {
            let room = MatrixServices.inst.session.room(withRoomId: roomId)
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
                cell?.RoomAliasPrimary.state = room!.state.canonicalAlias == alias ? .on : .off
                if !alias.hasSuffix(MatrixServices.inst.client.homeserverSuffix) {
                    cell?.RoomAliasName.isEnabled = false
                    cell?.RoomAliasDelete.isEnabled = false
                    cell?.RoomAliasPrimary.isEnabled = false
                }
                roomAliases.append(cell!)
            }
        }
    }
    
    @IBOutlet var AliasTable: NSTableView!
    
    var canonicalRoomAlias: String = ""
    var roomAliases: [RoomAliasEntry] = []
    var roomId: String = ""
    
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
        AliasTable.removeRows(at: IndexSet.init(integer: index!), withAnimation: [ .slideUp, .effectFade ])
        AliasTable.noteNumberOfRowsChanged()
    }
    
    @IBAction func addButtonClicked(_ sender: NSButton) {
        let suffix = MatrixServices.inst.client.homeserverSuffix ?? ":matrix.org"
        let cell = AliasTable.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomAliasEntry"), owner: self) as? RoomAliasEntry
        cell?.parent = self
        cell?.RoomAliasName.placeholderString = "#youralias\(suffix)"
        roomAliases.append(cell!)
        AliasTable.noteNumberOfRowsChanged()
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        
    }
}
