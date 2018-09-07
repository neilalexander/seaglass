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
    @IBOutlet weak var PreventUnverifiedCheckbox: NSButton!
    
    var roomId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
            EnableEncryptionCheckbox.state = room.state.isEncrypted ? .on : .off
            EnableEncryptionCheckbox.isEnabled = EnableEncryptionCheckbox.state == .off
        }
        
        PreventUnverifiedCheckbox.state = MatrixServices.inst.session.crypto.warnOnUnknowDevices ? .on : .off
    }
    
    
    @IBAction func allowUnverifiedCheckboxChanged(_ sender: NSButton) {
        if sender != PreventUnverifiedCheckbox {
            return
        }
        
        MatrixServices.inst.session.crypto.warnOnUnknowDevices = PreventUnverifiedCheckbox.state == .on
        UserDefaults.standard.set(MatrixServices.inst.session.crypto.warnOnUnknowDevices, forKey: "CryptoParanoid")
    }
    
}
