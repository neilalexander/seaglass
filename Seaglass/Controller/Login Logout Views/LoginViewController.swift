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

class LoginSuccessfulSegue: NSStoryboardSegue {
    override func perform() {
        if let src = self.sourceController as? LoginViewController, let dest = self.destinationController as? MainWindowController {
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.5
                src.view.window!.animator().alphaValue = 0
            }, completionHandler: {
                src.view.window!.close()
                dest.showWindow(src)
            })
        }
    }
}

class LoginViewController: NSViewController {

    let defaults = UserDefaults.standard
    
    @IBOutlet weak var InfoLabel: NSTextField!
    @IBOutlet weak var LoginButton: NSButton!
    @IBOutlet weak var CancelButton: NSButton!
    @IBOutlet weak var AdvancedSettingsButton: NSButton!
    @IBOutlet weak var UsernameField: NSTextField!
    @IBOutlet weak var UsernameLabel: NSTextField!
    @IBOutlet weak var PasswordField: NSSecureTextField!
    @IBOutlet weak var PasswordLabel: NSTextField!
    @IBOutlet weak var ProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var RememberCheckbox: NSButton!

    override func viewDidAppear() {
        super.viewDidAppear()
    
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUsernamePlaceholder), name: UserDefaults.didChangeNotification, object: nil)
        
        UsernameField.stringValue = defaults.string(forKey: "UserID") ?? ""
        if UsernameField.stringValue != "" {
            PasswordField.becomeFirstResponder()
        }
        
        if defaults.string(forKey: "Homeserver") == nil {
            defaults.setValue("https://matrix.org", forKey: "Homeserver")
        }
        refreshUsernamePlaceholder()
        
        if defaults.bool(forKey: "LoginAutomatically") &&
            defaults.string(forKey: "Homeserver") != nil &&
            defaults.string(forKey: "UserID") != nil &&
            defaults.string(forKey: "AccessToken") != nil &&
            defaults.string(forKey: "DeviceID") != nil {
            let credentials = MXCredentials(homeServer: defaults.string(forKey: "Homeserver"),
                                            userId: defaults.string(forKey: "UserID"),
                                            accessToken: defaults.string(forKey: "AccessToken"))
            credentials!.deviceId = defaults.string(forKey: "DeviceID")

            LoginButton.isEnabled = false
            CancelButton.title = "Cancel"
            
            UsernameField.isEnabled = false
            PasswordField.isEnabled = false
            RememberCheckbox.isEnabled = false
            AdvancedSettingsButton.isEnabled = false
            
            ProgressIndicator.isIndeterminate = true
            ProgressIndicator.startAnimation(self)
            
            print("Starting Matrix")
            MatrixServices.inst.start(credentials!, disableCache: defaults.bool(forKey: "DisableCache"), success: {
                print("Started successfully - handing over to main view")
                self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("OpenMainView"), sender: nil)
            }) {
                print("Failed to start")
            }
        }
    }
    
    @objc func refreshUsernamePlaceholder() {
        let homeserver = URL(string: defaults.string(forKey: "Homeserver") ?? "https://matrix.org")!.host ?? "matrix.org"
        UsernameField.placeholderString = "\(homeserver) username"
        PasswordField.placeholderString = "\(homeserver) password"
        AdvancedSettingsButton.title = " \(homeserver)"
    }
    
    @IBAction func LoginButtonClicked(_ sender: NSButton) {
        var hideObjects : [NSView] = [ LoginButton, AdvancedSettingsButton ]
        var showObjects : [NSView] = [ ProgressIndicator ]
        
        let username = UsernameField.stringValue
        let password = PasswordField.stringValue
        let homeserver = defaults.string(forKey: "Homeserver")!
        
        LoginButton.isEnabled = false
        CancelButton.title = "Cancel"
        
        UsernameField.isEnabled = false
        PasswordField.isEnabled = false
        RememberCheckbox.isEnabled = false
        AdvancedSettingsButton.isEnabled = false
        
        ProgressIndicator.isIndeterminate = true
        ProgressIndicator.startAnimation(self)
        
        self.defaults.set(self.RememberCheckbox.state == .on, forKey: "LoginAutomatically")
        self.defaults.removeObject(forKey: "AccessToken")
        self.defaults.removeObject(forKey: "UserID")
        self.defaults.removeObject(forKey: "DeviceID")

        print("Username: \(username)")
        print("Homeserver: \(homeserver)")
        
        let client = MXRestClient(homeServer: URL(string: homeserver)!, unrecognizedCertificateHandler: nil)
        print("Logging in")
        client.login(username: username, password: password) { response in
            switch response {
            case .success(let credentials):
                print("Login success")
                showObjects.append(self.ProgressIndicator)
                hideObjects.append(self.InfoLabel)
                hideObjects.append(self.UsernameField)
                hideObjects.append(self.UsernameLabel)
                hideObjects.append(self.PasswordField)
                hideObjects.append(self.PasswordLabel)
                hideObjects.append(self.CancelButton)
                hideObjects.append(self.RememberCheckbox)
                
                for hide in hideObjects {
                    NSAnimationContext.runAnimationGroup({ (context) in
                        context.duration = 0.25
                        hide.animator().alphaValue = 0
                    }, completionHandler: {
                        hide.isHidden = true
                    })
                }
                for show in showObjects {
                    show.isHidden = false
                    show.layer?.removeAllAnimations()
                    NSAnimationContext.runAnimationGroup({ (context) in
                        context.duration = 0.25
                        show.animator().alphaValue = 1
                    })
                }
                
                if self.RememberCheckbox.state == .on {
                    self.defaults.set(credentials.accessToken, forKey: "AccessToken")
                    self.defaults.set(credentials.homeServer, forKey: "Homeserver")
                    self.defaults.set(credentials.userId, forKey: "UserID")
                    self.defaults.set(credentials.deviceId, forKey: "DeviceID")
                }
                
                print("Starting Matrix")
                MatrixServices.inst.start(credentials, disableCache: self.defaults.bool(forKey: "DisableCache"), success: {
                    print("Started successfully - handing over to main view")
                    self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("OpenMainView"), sender: nil)
                }) {
                    print("Failed to start")
                }
                self.CancelButton.isEnabled = false
                break
                
            case .failure:
                print("Login failed")
                self.ProgressIndicator.stopAnimation(self)
                let a = NSAlert()
                a.messageText = "Login failed"
                a.informativeText = response.error!.localizedDescription
                a.addButton(withTitle: "OK")
                a.alertStyle = NSAlert.Style.warning
                a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
                    self.UsernameField.isEnabled = true
                    self.PasswordField.isEnabled = true
                    self.RememberCheckbox.isEnabled = true
                    self.AdvancedSettingsButton.isEnabled = true
                    
                    self.LoginButton.isEnabled = true
                    self.CancelButton.title = "Quit"
                })
                break
            }
        }
    }
    
    @IBAction func CancelButtonClicked(_ sender: NSButton) {
        if sender.title == "Cancel" {
            MatrixServices.inst.client?.close()
            
            let showObjects : [NSView] = [ LoginButton, AdvancedSettingsButton, UsernameField, UsernameLabel, PasswordField, PasswordLabel, CancelButton, RememberCheckbox, InfoLabel ]
            let hideObjects : [NSView] = [ ProgressIndicator ]
            
            for hide in hideObjects {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.25
                    hide.animator().alphaValue = 0
                }, completionHandler: {
                    hide.isHidden = true
                })
            }
            
            CancelButton.title = "Quit"
            
            LoginButton.isEnabled = true
            UsernameField.isEnabled = true
            PasswordField.isEnabled = true
            RememberCheckbox.isEnabled = true
            
            ProgressIndicator.stopAnimation(self)
            
            for show in showObjects {
                show.isHidden = false
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.25
                    show.animator().alphaValue = 1
                })
            }
        } else if sender.title == "Quit" {
            NSApplication.shared.terminate(self)
        }
    }
}

