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

class PopoverRoomActions: NSViewController {
    
    @IBOutlet weak var InviteButton: NSButton!
    @IBOutlet weak var AttachButton: NSButton!
    @IBOutlet weak var CallButton: NSButton!
    @IBOutlet weak var VideoButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func inviteButtonClicked(_ sender: NSButton) {
        MatrixServices.inst.mainController?.channelDelegate?.uiRoomStartInvite()
        self.dismiss(sender)
    }
    
}
