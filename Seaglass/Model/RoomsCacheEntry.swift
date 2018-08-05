//
//  RoomCacheEntry.swift
//  Seaglass
//
//  Created by Neil Alexander on 17/06/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

class RoomsCacheEntry: NSObject {
    var room: MXRoom
    
    @objc dynamic var roomId: String = ""
    @objc dynamic var roomName: String = ""
    @objc dynamic var roomAlias: String = ""
    @objc dynamic var roomTopic: String = ""
    
    init(_ room: MXRoom) {
        self.room = room
        
        self.roomId = room.roomId
        if room.state.name != nil {
            self.roomName = room.state.name
        }
        if room.state.canonicalAlias != nil {
            self.roomAlias = room.state.canonicalAlias
        }
        if room.state.topic != nil {
            self.roomTopic = room.state.topic
        }
        
        super.init()
    }
    
    func members() -> [MXRoomMember] {
        return self.room.state.members
    }
    
    func topic() -> String {
        return self.room.state.topic
    }
    
    func unread() -> Bool {
        return self.room.summary.localUnreadEventCount > 0
    }
}
