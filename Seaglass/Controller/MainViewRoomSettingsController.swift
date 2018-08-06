//
//  MainViewRoomSettingsController.swift
//  Seaglass
//
//  Created by Neil Alexander on 06/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class MainViewRoomSettingsController: NSViewController {
    @IBOutlet var RoomName: NSTextField!
    @IBOutlet var RoomTopic: NSTextField!
    @IBOutlet var RoomPublishInDirectory: NSButton!
    
    public var roomId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if roomId == "" {
            self.dismissViewController(self)
            return
        }
        
        RoomName.stringValue = MatrixServices.inst.session.room(withRoomId: roomId).state.name ?? ""
        RoomTopic.stringValue = MatrixServices.inst.session.room(withRoomId: roomId).state.topic ?? ""
        
        MatrixServices.inst.session.room(withRoomId: roomId).getDirectoryVisibility(completion: { (visibility) in
            if visibility.isSuccess {
                self.RoomPublishInDirectory.isEnabled = true
                self.RoomPublishInDirectory.state = visibility.value == .public ? .on : .off
            } else {
                self.RoomPublishInDirectory.state = .off
            }
        })
    }
    
}
