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

class LoginViewSettingsController: NSViewController {

    @IBOutlet var HomeserverURLField: NSTextField!
    @IBOutlet var DisableCacheCheckbox: NSButton!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if defaults.string(forKey: "Homeserver") != nil {
            HomeserverURLField.stringValue = defaults.string(forKey: "Homeserver")!
        }
        
        if defaults.bool(forKey: "DisableCache") {
            DisableCacheCheckbox.state = .on
        }
    }
    
    override func viewWillDisappear() {
        homeserverURLFieldEdited(sender: HomeserverURLField)
    }
    
    @IBAction func homeserverURLFieldEdited(sender: NSTextField) {
        defaults.setValue(HomeserverURLField.stringValue, forKey: "Homeserver")
    }
    
    @IBAction func disableCacheCheckboxEdited(sender: NSButton) {
        defaults.setValue(DisableCacheCheckbox.state == .on, forKey: "DisableCache")
    }
}
