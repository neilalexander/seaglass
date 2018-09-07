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

class MainViewEncryptionController: NSViewController {

    @IBOutlet weak var EnableEncryptionCheckbox: NSButton!
    @IBOutlet weak var AllowUnverifiedCheckbox: NSButton!
    
    var roomId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
            EnableEncryptionCheckbox.state = room.state.isEncrypted ? .on : .off
            EnableEncryptionCheckbox.isEnabled = EnableEncryptionCheckbox.state == .off
        }
        
        AllowUnverifiedCheckbox.state = MatrixServices.inst.session.crypto.warnOnUnknowDevices ? .off : .on
    }
    
    
    @IBAction func allowUnverifiedCheckboxChanged(_ sender: NSButton) {
        if sender != AllowUnverifiedCheckbox {
            return
        }
        
        MatrixServices.inst.session.crypto.warnOnUnknowDevices = AllowUnverifiedCheckbox.state == .off
        UserDefaults.standard.set(MatrixServices.inst.session.crypto.warnOnUnknowDevices, forKey: "CryptoParanoid")
    }
    
}
