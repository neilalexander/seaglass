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

class UserSettingsEncryptionController: UserSettingsTabController {

    @IBOutlet weak var DeviceName: NSTextField!
    @IBOutlet weak var DeviceID: NSTextField!
    @IBOutlet weak var DeviceKey: NSTextField!
    
    @IBOutlet weak var ParanoidMode: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resizeToSize = NSSize(width: 450, height: 265)
   
        if let crypto = MatrixServices.inst.session.crypto {
            
            if let device = crypto.deviceList.device(withIdentityKey: crypto.deviceCurve25519Key, forUser: MatrixServices.inst.session.myUser.userId, andAlgorithm: "m.megolm.v1.aes-sha2") {
                DeviceName.stringValue = device.displayName ?? ""
                DeviceID.stringValue = device.deviceId ?? ""
                DeviceKey.stringValue = String(device.fingerprint.enumerated().map { $0 > 0 && $0 % 4 == 0 ? [" ", $1] : [$1]}.joined())
            }
        }
        
        ParanoidMode.state = MatrixServices.inst.session.crypto.warnOnUnknowDevices ? .on : .off
    }
    
    @IBAction func paranoidModeChanged(_ sender: NSButton) {
        guard sender == ParanoidMode else { return }
        
        MatrixServices.inst.session.crypto.warnOnUnknowDevices = ParanoidMode.state == .on
        UserDefaults.standard.set(MatrixServices.inst.session.crypto.warnOnUnknowDevices, forKey: "CryptoParanoid")
    }
    
}
