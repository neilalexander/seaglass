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

class UserSettingsProfileController: UserSettingsTabController {
    
    @IBOutlet weak var showMostRecentMessageButton: NSButton!
    @IBOutlet weak var showRoomTopicButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resizeToSize = NSSize(width: 450, height: 75)
    }
    
    @IBAction func sidebarPreferenceChanged(_ sender: NSButton) {
        // the buttons need to be set to the same action so they act as a group
    }

}
