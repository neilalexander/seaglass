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

    @IBOutlet weak var DownloadSpinner: NSProgressIndicator!
    
    @IBOutlet weak var DeviceName: NSTextField!
    @IBOutlet weak var DeviceID: NSTextField!
    @IBOutlet weak var DeviceFingerprint: NSTextField!
    
    @IBOutlet weak var MessageAlgorithm: NSTextField!
    
    @IBOutlet weak var DeviceVerified: NSButton!
    @IBOutlet weak var DeviceBlacklisted: NSButton!
    
    var event: MXEvent?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DownloadSpinner.isHidden = true
        
        guard event != nil else {
            DeviceVerified.isEnabled = false
            DeviceBlacklisted.isEnabled = false
            return
        }
        
        let deviceInfo: MXDeviceInfo? = MatrixServices.inst.session.crypto.eventDeviceInfo(self.event)
        
       // if MatrixServices.inst.session.myUser.userId == event!.sender {
       //     deviceInfo = MatrixServices.inst.session.crypto.eventSenderDevice(of: event)
       // } else {
       //     deviceInfo = MatrixServices.inst.session.crypto.eventDeviceInfo(event)
       // }

        if let deviceInfo = deviceInfo {
            DeviceName.stringValue = deviceInfo.displayName ?? ""
            DeviceID.stringValue = deviceInfo.deviceId ?? ""
            DeviceFingerprint.stringValue = String(deviceInfo.fingerprint.enumerated().map { $0 > 0 && $0 % 4 == 0 ? [" ", $1] : [$1]}.joined())
            
            if deviceInfo.userId == MatrixServices.inst.session.myUser.userId {
                DeviceVerified.isEnabled = deviceInfo.deviceId != MatrixServices.inst.client.credentials.deviceId
                DeviceBlacklisted.isEnabled = DeviceVerified.isEnabled
            }

            DeviceVerified.state = deviceInfo.verified == MXDeviceVerified ? .on : .off
            DeviceBlacklisted.state = deviceInfo.verified == MXDeviceBlocked ? .on : .off
        } else {
            DeviceVerified.isEnabled = false
            DeviceBlacklisted.isEnabled = false
            
            DownloadSpinner.isHidden = false
            DownloadSpinner.startAnimation(self)
            
            MatrixServices.inst.session.crypto.downloadKeys([event!.sender], forceDownload: false, success: { (devicemap) in
                self.DownloadSpinner.stopAnimation(self)
                self.DownloadSpinner.isHidden = true

                let deviceInfo: MXDeviceInfo? = MatrixServices.inst.session.crypto.eventDeviceInfo(self.event)
                
               // if MatrixServices.inst.session.myUser.userId == self.event!.sender {
               //     deviceInfo = MatrixServices.inst.session.crypto.eventSenderDevice(of: self.event)
               // } else {
               //     deviceInfo = MatrixServices.inst.session.crypto.eventDeviceInfo(self.event)
               // }
                
                if deviceInfo != nil {
                    print("Got device info")
                    self.viewDidLoad()
                } else {
                    print("No device info")
                }
            }) { (error) in
                OperationQueue.main.addOperation {
                    self.DownloadSpinner.stopAnimation(self)
                    self.DownloadSpinner.isHidden = true
                }
            }
        }
        
        MessageAlgorithm.stringValue = event!.wireContent["algorithm"] as? String ?? ""
    }
    
    @IBAction func deviceVerificationChanged(_ sender: NSButton) {
        guard sender == DeviceVerified || sender == DeviceBlacklisted else { return }
        guard event != nil else { return }
        
        if let deviceInfo = MatrixServices.inst.session.crypto.eventSenderDevice(of: event) {
            if sender == DeviceVerified {
                if DeviceVerified.state == .on {
                    DeviceBlacklisted.state = .off
                }
            }
            
            if sender == DeviceBlacklisted {
                if DeviceBlacklisted.state == .on {
                    DeviceVerified.state = .off
                }
            }
            
            let verificationState =
                DeviceBlacklisted.state == .on ? MXDeviceBlocked :
                DeviceVerified.state == .on ? MXDeviceVerified : MXDeviceUnverified
            
            DeviceVerified.isEnabled = false
            DeviceBlacklisted.isEnabled = false
        
            MatrixServices.inst.session.crypto.setDeviceVerification(verificationState, forDevice: deviceInfo.deviceId, ofUser: deviceInfo.userId, success: {
                self.DeviceVerified.isEnabled = true
                self.DeviceBlacklisted.isEnabled = true
                
                MatrixServices.inst.mainController?.channelDelegate?.uiRoomNeedsCryptoReload()
            }) { (error) in
                self.DeviceVerified.state = deviceInfo.verified == MXDeviceVerified ? .on : .off
                self.DeviceBlacklisted.state = deviceInfo.verified == MXDeviceBlocked ? .on : .off
                
                self.DeviceVerified.isEnabled = true
                self.DeviceBlacklisted.isEnabled = true
            }
        }
    }
    
}
