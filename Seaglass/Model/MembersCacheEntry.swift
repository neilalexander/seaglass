//
//  MembersCacheEntry.swift
//  Seaglass
//
//  Created by Neil Alexander on 06/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

class MembersCacheEntry: NSObject {
    var member: MXRoomMember
    
    @objc dynamic var displayName: String = ""
    @objc dynamic var userId: String = ""
    
    init(_ member: MXRoomMember) {
        self.member = member
        
        self.userId = member.userId
        if member.displayname != nil {
            self.displayName = member.displayname
        }
        
        super.init()
    }
    
    func name() -> String {
        if self.displayName != "" {
            return self.displayName
        }
        return self.userId
    }
}
