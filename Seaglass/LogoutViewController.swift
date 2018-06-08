//
//  LogoutViewController.swift
//  Seaglass
//
//  Created by Neil Alexander on 09/06/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class LogoutViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MatrixServices.inst.logout()
    }
    
}
