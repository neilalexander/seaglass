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
    @IBOutlet weak var ConfirmButton: NSButton!
    @IBOutlet weak var ConfirmSpinner: NSProgressIndicator!
    
    var roomId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ConfirmButton.isEnabled = false
        ConfirmButton.alphaValue = 1
        ConfirmSpinner.alphaValue = 0
        
        if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
            room.state { state in
                self.EnableEncryptionCheckbox.state = state!.isEncrypted ? .on : .off
                self.EnableEncryptionCheckbox.isEnabled = self.EnableEncryptionCheckbox.state == .off
            }
        } else {
            EnableEncryptionCheckbox.isEnabled = false
        }
        
        PreventUnverifiedCheckbox.state = MatrixServices.inst.session.crypto.warnOnUnknowDevices ? .on : .off
    }
    
    
    @IBAction func allowUnverifiedCheckboxChanged(_ sender: NSButton) {
        guard sender == PreventUnverifiedCheckbox else { return }
        
        MatrixServices.inst.session.crypto.warnOnUnknowDevices = PreventUnverifiedCheckbox.state == .on
        UserDefaults.standard.set(MatrixServices.inst.session.crypto.warnOnUnknowDevices, forKey: "CryptoParanoid")
    }
    
    @IBAction func enableEncryptionCheckboxChanged(_ sender: NSButton) {
        guard sender == EnableEncryptionCheckbox else { return }
        
        ConfirmButton.isEnabled =
            EnableEncryptionCheckbox.isEnabled &&
            EnableEncryptionCheckbox.state == .on
    }
    
    
    @IBAction func confirmButtonPressed(_ sender: NSButton) {
        guard sender == ConfirmButton else { return }
        guard EnableEncryptionCheckbox.isEnabled else { return }
        guard roomId != "" else { return }
        
        ConfirmButton.isEnabled = false
        ConfirmSpinner.startAnimation(self)
        
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            ConfirmButton.animator().alphaValue = 0
            ConfirmSpinner.animator().alphaValue = 1
        }, completionHandler: {
            if let room = MatrixServices.inst.session.room(withRoomId: self.roomId) {
                room.enableEncryption(withAlgorithm: "m.megolm.v1.aes-sha2") { (response) in
                    if response.isSuccess {
                        self.dismiss(self)
                        return
                    }
                    
                    print("Failed to enable encryption: \(response.error!.localizedDescription)")
                    self.dismiss(self)
                }
            }
        })
    }
}
