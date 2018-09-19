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
    
    @IBOutlet weak var DeviceNameSpinner: NSProgressIndicator!
    
    @IBOutlet weak var ParanoidMode: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resizeToSize = NSSize(width: 450, height: 359)
        
        DeviceNameSpinner.isHidden = false
        DeviceNameSpinner.startAnimation(self)
   
        MatrixServices.inst.client.device(withId: MatrixServices.inst.client.credentials.deviceId, completion: { (response) in
            if response.isSuccess {
                if let device = response.value {
                    self.DeviceName.stringValue = device.displayName ?? ""
                }
                
                self.DeviceNameSpinner.stopAnimation(self)
                self.DeviceNameSpinner.isHidden = true
            }
        })
        self.DeviceID.stringValue = MatrixServices.inst.client.credentials.deviceId
        self.DeviceKey.stringValue = String(MatrixServices.inst.session.crypto.deviceEd25519Key.enumerated().map { $0 > 0 && $0 % 4 == 0 ? [" ", $1] : [$1]}.joined())
        
        ParanoidMode.state = MatrixServices.inst.session.crypto.warnOnUnknowDevices ? .on : .off
    }
    
    @IBAction func paranoidModeChanged(_ sender: NSButton) {
        guard sender == ParanoidMode else { return }
        
        MatrixServices.inst.session.crypto.warnOnUnknowDevices = ParanoidMode.state == .on
        UserDefaults.standard.set(MatrixServices.inst.session.crypto.warnOnUnknowDevices, forKey: "CryptoParanoid")
    }
    
    @IBAction func importKeysPressed(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.title = "Export Keys"
        panel.allowedFileTypes = ["txt"]
        panel.allowsOtherFileTypes = true
        
        let openresponse = panel.runModal()
        guard openresponse != .cancel else { return }
        
        var data: Data?
        do {
            data = try Data(contentsOf: panel.url!)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to import room keys"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            return
        }
        
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Enter import password"
        alert.informativeText = "Enter the password that you used when exporting your encryption keys."
        
        let password = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        password.placeholderString = "Password"
        
        alert.accessoryView = password
        var response: NSApplication.ModalResponse = .cancel
        while password.stringValue == "" {
            response = alert.runModal()
            if response == .alertSecondButtonReturn {
                break
            }
        }
        
        MatrixServices.inst.session.crypto.importRoomKeys(data!, withPassword: password.stringValue, success: {
            let alert = NSAlert()
            alert.messageText = "Room keys imported"
            alert.informativeText = "Your encryption keys have been imported."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }) { (error) in
            let alert = NSAlert()
            alert.messageText = "Failed to import room keys"
            alert.informativeText = error!.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @IBAction func exportKeysPressed(_ sender: NSButton) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Enter export password"
        alert.informativeText = "This password will protect your encryption keys. You will need to use the same password to import the keys later."
        
        let password = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        password.placeholderString = "Password"
        
        alert.accessoryView = password
        var response: NSApplication.ModalResponse = .cancel
        while password.stringValue == "" {
            response = alert.runModal()
            if response == .alertSecondButtonReturn {
                break
            }
        }
        
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            let panel = NSSavePanel()
            panel.title = "Export Keys"
            panel.allowedFileTypes = ["txt"]
            panel.allowsOtherFileTypes = true
            panel.nameFieldStringValue = "keys.txt"
            
            let saveresponse = panel.runModal()
            guard saveresponse != .cancel else { return }
            
            MatrixServices.inst.session.crypto.exportRoomKeys(withPassword: password.stringValue, success: { (data) in
                do {
                    try data!.write(to: panel.url!)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Failed to export room keys"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    
                    return
                }
                
                let alert = NSAlert()
                alert.messageText = "Room keys exported"
                alert.informativeText = "Your encryption keys have been exported."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }) { (error) in
                let alert = NSAlert()
                alert.messageText = "Failed to export room keys"
                alert.informativeText = error!.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                
                return
            }
            
            break
        default:
            print("Cancel")
        }
    }
    
}
