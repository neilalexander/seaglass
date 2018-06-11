//
// Seaglass, a native macOS Matrix client
// Copyright © 2018, Neil Alexander
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Cocoa
import SwiftMatrixSDK

class ReplaceWindowSegue: NSStoryboardSegue {
    override func perform() {
        if let src = self.sourceController as? NSViewController,
            let dest = self.destinationController as? NSViewController {
            
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.5
                src.view.window?.animator().alphaValue = 0
                dest.view.window?.animator().alphaValue = 1
            })
        }
    }
}

class ReplaceSheetSegue: NSStoryboardSegue {
    override func perform() {
        if let src = self.sourceController as? NSViewController,
            let dest = self.destinationController as? NSViewController,
            let window = src.view.window {

            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.5
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.contentViewController = dest
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.5
                    window.animator().alphaValue = 1
                })
            })
        }
    }
}

class LoginViewController: NSViewController, MatrixServicesDelegate, ViewControllerWithDelegates {
    
    weak var roomsController: MainViewRoomsController?
    weak var channelController: MainViewRoomController?
    
    weak var servicesDelegate: MatrixServicesDelegate?
    weak var roomsDelegate: MatrixRoomsDelegate?
    weak var channelDelegate: MatrixRoomDelegate?

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
    @IBOutlet weak var AdvancedSettingsLabel: NSTextField!
    @IBOutlet weak var RememberCheckbox: NSButton!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        servicesDelegate = self
        
        UsernameField.stringValue = defaults.string(forKey: "UserID") ?? ""
        if UsernameField.stringValue != "" {
            PasswordField.becomeFirstResponder()
        }
        
        if defaults.string(forKey: "Homeserver") == nil {
            defaults.setValue("https://matrix.org", forKey: "Homeserver")
        }
        
        if defaults.bool(forKey: "LoginAutomatically") {
            let credentials = MXCredentials(homeServer: defaults.string(forKey: "Homeserver"),
                                            userId: defaults.string(forKey: "UserID"),
                                            accessToken: defaults.string(forKey: "AccessToken"))

            LoginButton.isEnabled = false
            CancelButton.title = "Cancel"
            
            UsernameField.isEnabled = false
            PasswordField.isEnabled = false
            RememberCheckbox.isEnabled = false
            AdvancedSettingsButton.isEnabled = false
            
            ProgressIndicator.isIndeterminate = true
            ProgressIndicator.startAnimation(self)
            
            MatrixServices.inst.start(credentials!)
        }
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
        
        if self.RememberCheckbox.state != .on {
            self.defaults.removeObject(forKey: "AccessToken")
            self.defaults.removeObject(forKey: "UserID")
        }

        let client = MXRestClient(homeServer: URL(string: homeserver)!, unrecognizedCertificateHandler: nil)
        client.login(username: username, password: password) { response in
            switch response {
            case .success(let credentials):
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
                }
                
                MatrixServices.inst.start(credentials)
                self.CancelButton.isEnabled = false
                
            case .failure:
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
    
    override func viewDidLoad() {
        MatrixServices.inst.mainController = self
        
        super.viewDidLoad()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func matrixDidLogin(_ session: MXSession) {
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("OpenMainView"), sender: nil)
    }
    
    func matrixWillLogout() {
        
    }
    
    func matrixDidLogout() {
        
    }
}

