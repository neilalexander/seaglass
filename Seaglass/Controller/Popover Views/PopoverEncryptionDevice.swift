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

class PopoverEncryptionDevice: NSViewController {

    @IBOutlet weak var DeviceName: NSTextField!
    @IBOutlet weak var DeviceID: NSTextField!
    @IBOutlet weak var DeviceFingerprint: NSTextField!
    
    @IBOutlet weak var MessageIdentity: NSTextField!
    @IBOutlet weak var MessageFingerprint: NSTextField!
    @IBOutlet weak var MessageAlgorithm: NSTextField!
    
    var event: MXEvent?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard event != nil else { return }
        
        if let deviceInfo = MatrixServices.inst.session.crypto.eventSenderDevice(of: event) {
            DeviceName.stringValue = deviceInfo.displayName ?? ""
            DeviceID.stringValue = deviceInfo.deviceId ?? ""
            DeviceFingerprint.stringValue = deviceInfo.fingerprint ?? ""
        }
        
        MessageIdentity.stringValue = event!.senderKey ?? ""
        MessageFingerprint.stringValue = event!.claimedEd25519Key ?? ""
        MessageAlgorithm.stringValue = event!.wireContent["algorithm"] as? String ?? ""
        
        let fingerprintColor = MessageFingerprint.stringValue != DeviceFingerprint.stringValue ? NSColor.systemRed : NSColor.labelColor
        DeviceFingerprint.textColor = fingerprintColor
        MessageFingerprint.textColor = fingerprintColor
    }
    
}
