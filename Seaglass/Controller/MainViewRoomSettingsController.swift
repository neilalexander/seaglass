//
//  MainViewRoomSettingsController.swift
//  Seaglass
//
//  Created by Neil Alexander on 06/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

class MainViewRoomSettingsController: NSViewController {
    @IBOutlet var RoomName: NSTextField!
    @IBOutlet var RoomTopic: NSTextField!
    @IBOutlet var RoomPublishInDirectory: NSButton!
    
    @IBOutlet var RoomAccessOnlyInvited: NSButton!
    @IBOutlet var RoomAccessExceptGuests: NSButton!
    @IBOutlet var RoomAccessIncludingGuests: NSButton!
    
    @IBOutlet var RoomHistorySinceJoined: NSButton!
    @IBOutlet var RoomHistorySinceInvited: NSButton!
    @IBOutlet var RoomHistorySinceSelected: NSButton!
    @IBOutlet var RoomHistoryAnyone: NSButton!
    
    public var roomId: String = ""
    
    @IBAction func accessRadioClicked(_ sender: NSButton) {
        for radio in [ RoomAccessOnlyInvited, RoomAccessExceptGuests, RoomAccessIncludingGuests ] {
            radio?.state = .off
        }
        sender.state = .on
    }
    
    @IBAction func historyRadioClicked(_ sender: NSButton) {
        for radio in [ RoomHistorySinceJoined, RoomHistorySinceInvited, RoomHistorySinceSelected, RoomHistoryAnyone ] {
            radio?.state = .off
        }
        sender.state = .on
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if roomId == "" {
            self.dismissViewController(self)
            return
        }
        
        let room = MatrixServices.inst.session.room(withRoomId: roomId) as MXRoom
        
        RoomName.stringValue = room.state.name ?? ""
        RoomTopic.stringValue = room.state.topic ?? ""
        
        room.getDirectoryVisibility(completion: { (visibility) in
            if visibility.isSuccess {
                self.RoomPublishInDirectory.isEnabled = true
                self.RoomPublishInDirectory.state = visibility.value == .public ? .on : .off
            } else {
                self.RoomPublishInDirectory.state = .off
            }
        })
        
        RoomAccessOnlyInvited.state = !room.state.isJoinRulePublic ? .on : .off
        RoomAccessExceptGuests.state = room.state.isJoinRulePublic && room.state.guestAccess == .forbidden ? .on : .off
        RoomAccessIncludingGuests.state = room.state.isJoinRulePublic && room.state.guestAccess == .canJoin ? .on : .off
        
        RoomHistorySinceJoined.state = room.state.historyVisibility == .invited ? .on : .off
        RoomHistorySinceInvited.state = room.state.historyVisibility == .joined ? .on : .off
        RoomHistorySinceSelected.state = room.state.historyVisibility == .shared ? .on : .off
        RoomHistoryAnyone.state = room.state.historyVisibility == .worldReadable ? .on : .off
    }
    
}
