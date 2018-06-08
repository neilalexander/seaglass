//
//  LoginViewSettingsController.swift
//  Seaglass
//
//  Created by Neil Alexander on 08/06/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class LoginViewSettingsController: NSViewController {

    @IBOutlet var HomeserverURLField: NSTextField!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if defaults.string(forKey: "Homeserver") != nil {
            HomeserverURLField.stringValue = defaults.string(forKey: "Homeserver")!
        }
    }
    
    override func viewWillDisappear() {
        homeserverURLFieldEdited(sender: HomeserverURLField)
    }
    
    @IBAction func homeserverURLFieldEdited(sender: NSTextField) {
        defaults.setValue(HomeserverURLField.stringValue, forKey: "Homeserver")
    }
    
}
