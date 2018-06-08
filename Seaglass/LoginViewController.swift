//
//  ViewController.swift
//  Matrix
//
//  Created by Neil Alexander on 05/06/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

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
    weak var channelController: MainViewChannelController?
    
    weak var servicesDelegate: MatrixServicesDelegate?
    weak var roomsDelegate: MatrixRoomsDelegate?
    weak var channelDelegate: MatrixChannelDelegate?

    let defaults = UserDefaults.standard
    
    @IBOutlet weak var LoginButton: NSButton!
    @IBOutlet weak var CancelButton: NSButton!
    @IBOutlet weak var AdvancedSettingsButton: NSButton!
    @IBOutlet weak var UsernameField: NSTextField!
    @IBOutlet weak var PasswordField: NSSecureTextField!
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
        
        if defaults.bool(forKey: "LoginAutomatically") {
            let credentials = MXCredentials(homeServer: defaults.string(forKey: "HomeServer"),
                                            userId: defaults.string(forKey: "UserID"),
                                            accessToken: defaults.string(forKey: "AccessToken"))

            LoginButton.isEnabled = false
            CancelButton.title = "Cancel"
            
            UsernameField.isEnabled = false
            PasswordField.isEnabled = false
            RememberCheckbox.isEnabled = false
            
            ProgressIndicator.isIndeterminate = true
            ProgressIndicator.startAnimation(self)
            
            MatrixServices.inst.start(credentials!)
        }
    }
    
    @IBAction func LoginButtonClicked(_ sender: NSButton) {
        let hideObjects : [NSView] = [ LoginButton, AdvancedSettingsButton ]
        let showObjects : [NSView] = [ ProgressIndicator ]
        
        LoginButton.isEnabled = false
        CancelButton.title = "Cancel"
        
        UsernameField.isEnabled = false
        PasswordField.isEnabled = false
        RememberCheckbox.isEnabled = false
        
        ProgressIndicator.isIndeterminate = true
        ProgressIndicator.startAnimation(self)
        
        let address = "https://matrix.org"
        
        self.defaults.set(self.RememberCheckbox.state == .on, forKey: "LoginAutomatically")
        
        if self.RememberCheckbox.state != .on {
            self.defaults.removeObject(forKey: "AccessToken")
            self.defaults.removeObject(forKey: "HomeServer")
            self.defaults.removeObject(forKey: "UserID")
        }

        let client = MXRestClient(homeServer: URL(string: address)!, unrecognizedCertificateHandler: nil)
        client.login(username: UsernameField.stringValue, password: PasswordField.stringValue) { response in
            self.ProgressIndicator.stopAnimation(self)
            
            switch response {
            case .success(let credentials):
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
                    self.defaults.set(credentials.homeServer, forKey: "HomeServer")
                    self.defaults.set(credentials.userId, forKey: "UserID")
                }
                
                MatrixServices.inst.start(credentials)
                self.ProgressIndicator.stopAnimation(self)
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
                    
                    self.LoginButton.isEnabled = true
                    self.CancelButton.title = "Quit"
                })
            }
        }
    }
    
    @IBAction func CancelButtonClicked(_ sender: NSButton) {
        if sender.title == "Cancel" {
            MatrixServices.inst.client?.close()
            
            let showObjects : [NSView] = [ LoginButton, AdvancedSettingsButton ]
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
        print("LoginViewController matrixDidLogin")
        
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("OpenMainView"), sender: nil)
    }
    
    func matrixDidLogout() {
        print("LoginViewController matrixDidLogout")
        
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier("OpenLoginView"), sender: nil)
    }
}

