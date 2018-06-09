//
// Seaglass, a native macOS Matrix client
// Copyright © 2018, Neil Alexander
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Cocoa

class LoginViewSettingsController: NSViewController {

    @IBOutlet var HomeserverURLField: NSTextField!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if defaults.string(forKey: "Homeserver") != nil {
            HomeserverURLField.stringValue = defaults.string(forKey: "Homeserver")!
        }
    }
    
    override func viewWillDisappear() {
        homeserverURLFieldEdited(sender: HomeserverURLField)
    }
    
    @IBAction func homeserverURLFieldEdited(sender: NSTextField) {
        defaults.setValue(HomeserverURLField.stringValue, forKey: "Homeserver")
    }
    
}
