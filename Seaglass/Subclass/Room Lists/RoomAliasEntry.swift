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

class RoomAliasEntry: NSTableCellView {
    @IBOutlet var RoomAliasName: NSTextField!
    @IBOutlet var RoomAliasPrimary: NSButton!
    @IBOutlet var RoomAliasDelete: NSButton!
    
    public var parent: RoomAliasesController?
    
    @IBAction func makePrimary(_ sender: NSButton) {
        parent?.primaryButtonClicked(sender: self)
    }
    
    @IBAction func delete(_ sender: NSButton) {
        parent?.deleteButtonClicked(sender: self)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        RoomAliasName.isEditable = true
    }
}
