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

class RoomMessageInline: RoomMessage {
    @IBOutlet var Text: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func viewWillDraw() {
        if event == nil {
            return
        }
        let roomId = event!.roomId
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        if room == nil {
            return
        }
        Text.toolTip = super.timestamp(.medium, andDate: .medium)
        switch event!.type {
        case "m.room.member":
            let senderDisplayName = room!.state.memberName(event!.sender) ?? event!.sender as String
            let stateKeyDisplayName = room!.state.memberName(event!.stateKey) ?? event!.stateKey as String
            let prevDisplayName = event!.prevContent != nil && event!.prevContent.keys.contains("displayname") ? event!.prevContent["displayname"] as! String? : stateKeyDisplayName
            let newDisplayName = event!.content != nil && event!.content.keys.contains("displayname") ? event!.content["displayname"] as! String? : stateKeyDisplayName
            switch event!.content["membership"] as! String {
            case "join":
                let prevMembership = event!.prevContent != nil && event!.prevContent.keys.contains("membership") ? event!.prevContent["membership"] as! String : "leave"
                if prevMembership == "leave" {
                    Text.stringValue = "\(newDisplayName!) joined the room"
                    break
                }
                if newDisplayName != nil && prevDisplayName != nil && newDisplayName != prevDisplayName {
                    Text.stringValue = "\(prevDisplayName!) is now \(newDisplayName!)"
                } else if newDisplayName != nil {
                    Text.stringValue = "\(event!.stateKey!) is now \(newDisplayName!)"
                } else {
                    let prevAvatarUrl: String? = event!.prevContent.keys.contains("avatar_url") ? event!.prevContent["avatar_url"] as! String? : nil
                    let newAvatarUrl: String? = event!.content.keys.contains("avatar_url") ? event!.content["avatar_url"] as! String? : nil
                    if prevAvatarUrl != newAvatarUrl {
                        Text.stringValue = "\(newDisplayName!) changed their avatar"
                    } else {
                        Text.stringValue = "\(newDisplayName!) unknown state change event"
                    }
                }
                break
            case "leave":   Text.stringValue = "\(prevDisplayName!) left the room"; break
            case "invite":  Text.stringValue = "\(senderDisplayName) invited \(newDisplayName!)"; break
            case "ban":     Text.stringValue = "\(senderDisplayName) banned \(newDisplayName!)"; break
            default:        Text.stringValue = "\(newDisplayName!) unknown event: \(event!.stateKey)"; break
            }
            break
        case "m.room.name":
            if event!.content["name"] as! String != "" {
                Text.stringValue = "Room renamed: \(event!.content["name"] as! String)"
            } else {
                Text.stringValue = "Room name removed"
            }
            break
        case "m.room.topic":
            if event!.content["topic"] as! String != "" {
                Text.stringValue = "Room topic changed: \(event!.content["topic"] as! String)"
            } else {
                Text.stringValue = "Room topic removed"
            }
            break
        case "m.room.avatar":
            if event!.content["url"] as! String != "" {
                Text.stringValue = "Room avatar changed"
            } else {
                Text.stringValue = "Room avatar removed"
            }
            break
        case "m.room.canonical_alias":
            if event!.content["alias"] as! String != "" {
                Text.stringValue = "Primary room alias set to \(event!.content["alias"] as! String)"
            } else {
                Text.stringValue = "Primary room alias removed"
            }
            break
        case "m.room.create":
            let displayName = MatrixServices.inst.session.room(withRoomId: roomId).state.memberName(event!.content["creator"] as! String) ?? event!.content["creator"] as! String
            Text.stringValue = "Room created by \(displayName)"
            break
        case "m.room.encryption":
            let displayName = MatrixServices.inst.session.room(withRoomId: roomId).state.memberName(event!.sender) ?? event!.sender ?? "Room participant"
            Text.stringValue = "\(displayName) enabled room encryption (\(event!.content["algorithm"] ?? "unknown") algorithm)"
            break
        default:
            Text.stringValue = "Unknown event \(event!.type)"
        }
    }
}
