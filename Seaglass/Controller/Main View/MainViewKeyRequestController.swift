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
import SwiftMatrixSDK

class MainViewKeyRequestController: NSViewController {

    @IBOutlet weak var UserIDField: NSTextField!
    @IBOutlet weak var DeviceNameField: NSTextField!
    @IBOutlet weak var DeviceIDField: NSTextField!
    @IBOutlet weak var DeviceKeyField: NSTextField!
    @IBOutlet weak var ConfirmationCheckbox: NSButton!
    @IBOutlet weak var ShareButton: NSButton!
    @IBOutlet weak var DontShareButton: NSButton!
    @IBOutlet weak var IgnoreButton: NSButton!
    
    var request: MXIncomingRoomKeyRequest?
    
    override func viewWillAppear() {
        guard request != nil else { return }

        // TODO: This is the wrong key
        if let senderkey = request!.requestBody["sender_key"] as? String {
            DeviceKeyField.stringValue = String(senderkey.enumerated().map { $0 > 0 && $0 % 4 == 0 ? [" ", $1] : [$1]}.joined())
        } else {
            DeviceKeyField.stringValue = ""
        }
        
        DeviceNameField.stringValue = MatrixServices.inst.session.crypto.deviceList.storedDevice(request!.userId, deviceId: request!.deviceId).displayName
        
        UserIDField.stringValue = request!.userId
        DeviceIDField.stringValue = request!.deviceId
        
        ConfirmationCheckbox.state = .off
    }

    @IBAction func shareButtonPressed(_ sender: NSButton) {
        guard request != nil else { return }
        guard sender == ShareButton else { return }
        guard ConfirmationCheckbox.state == .on else { return }
        
        MatrixServices.inst.session.crypto.accept(request, success: {
            self.dismiss(sender)
        }) { (response) in
            let alert = NSAlert()
            alert.messageText = "Failed to share encryption keys"
            alert.informativeText = response?.localizedDescription ?? "No error detail was provided"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @IBAction func dontShareButtonPressed(_ sender: NSButton) {
        guard request != nil else { return }
        guard sender == DontShareButton else { return }
        
        MatrixServices.inst.session.crypto.ignore(request) {
            self.dismiss(sender)
        }
    }
    
    @IBAction func ignoreButtonPressed(_ sender: NSButton) {
        guard sender == IgnoreButton else { return }
        
        MatrixServices.inst.session.crypto.ignoreAllPendingKeyRequests(fromUser: request!.userId, andDevice: request!.deviceId) {
            self.dismiss(sender)
        }
    }
    
    @IBAction func confirmationCheckboxPressed(_ sender: NSButton) {
        guard sender == ConfirmationCheckbox else { return }
        ShareButton.isEnabled = sender.state == .on
    }
    
}
