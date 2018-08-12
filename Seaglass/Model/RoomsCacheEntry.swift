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
    
    @objc dynamic var roomId: String {
        return room.roomId
    }
    @objc dynamic var roomName: String {
        return room.state.name ?? ""
    }
    @objc dynamic var roomAlias: String {
        return room.state.canonicalAlias ?? ""
    }
    @objc dynamic var roomTopic: String  {
        return room.state.topic ?? ""
    }
    @objc dynamic var roomAvatar: String {
        return room.state.avatar ?? ""
    }
    @objc dynamic var roomSortWeight: Int {
        if self.room.isDirect || self.room.looksLikeDirect {
            return 70
        }
        if self.room.summary.isEncrypted || self.room.state.isEncrypted {
            return 10
        }
        if self.room.state.name == "" {
            if self.room.state.topic == "" {
                return 52
            }
            return 51
        }
        return 50
    }
    
    init(_ room: MXRoom) {
        self.room = room
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
