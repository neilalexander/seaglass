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

class RoomMessageInline: RoomMessage {
    @IBOutlet var Text: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func viewWillDraw() {
        guard event != nil else { return }
        guard let roomId = event!.roomId else { return }
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return }
        guard event != drawnEvent || event!.hash != drawnEventHash else { return }
        
        Text.allowsEditingTextAttributes = true
        
        Text.toolTip = super.timestamp(.medium, andDate: .medium)
        switch event!.type {
        case "m.room.encrypted":
            Text.stringValue = ""
            Text.placeholderString = "Unable to decrypt (waiting for keys)"
            break
        case "m.room.member":
            let current = event!.content ?? [:]
            let previous = event!.prevContent ?? [:]
            var changes: [String] = []
            
            for key in current.keys {
                if previous.keys.contains(key) {
                    if previous[key] as! String != current[key] as! String {
                        changes.append(key)
                    }
                } else {
                    changes.append(key)
                }
            }
            
            if changes.contains("membership") {
                changes = ["membership"]
            }

            let senderDisplayName = room.state.memberName(event!.sender) ?? event!.sender as String
            let prevDisplayName =
                event!.prevContent != nil && event!.prevContent.keys.contains("displayname") ?
                    event!.prevContent["displayname"] as! String? :
                    event!.stateKey as String
            let newDisplayName =
                event!.content != nil && event!.content.keys.contains("displayname") ?
                    event!.content["displayname"] as! String? :
                    event!.stateKey as String
            
            Text.stringValue = ""
            for change in changes {
                if Text.stringValue != "" {
                    Text.stringValue.append("\n")
                }
                switch change {
                case "membership":
                    switch current["membership"] as! String {
                        case "join":        Text.stringValue.append(contentsOf: "\(newDisplayName!) joined the room"); break
                        case "invite":      Text.stringValue.append(contentsOf: "\(senderDisplayName) invited \(newDisplayName!)"); break
                        case "leave":       Text.stringValue.append(contentsOf: "\(prevDisplayName!) left the room"); break
                        case "ban":         Text.stringValue.append(contentsOf: "\(senderDisplayName) banned \(newDisplayName!)"); break
                        default:            Text.stringValue.append(contentsOf: "\(newDisplayName!) unknown membership state: \(current["membership"] as! String)"); break
                    }
                    break
                case "displayname":       Text.stringValue.append(contentsOf: "\(prevDisplayName!) is now \(newDisplayName!)"); break
                case "avatar_url":        Text.stringValue.append(contentsOf: "\(newDisplayName!) changed their avatar"); break
                default:                  Text.stringValue.append(contentsOf: "\(newDisplayName!) unknown change: \(change)"); break
                }
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
            Text.stringValue = "(unknown event \(event!.type))"
        }
        if Text.stringValue == "" {
            Text.stringValue = "(no message)"
        }
        
        drawnEvent = event
        drawnEventHash = event!.content.count
    }
}
