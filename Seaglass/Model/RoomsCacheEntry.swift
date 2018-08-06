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
    
    func encrypted() -> Bool {
        return self.room.summary.isEncrypted || self.room.state.isEncrypted
    }
}
