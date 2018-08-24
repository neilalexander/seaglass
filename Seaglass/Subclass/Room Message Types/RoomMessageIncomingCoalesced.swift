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

class RoomMessageIncomingCoalesced: RoomMessage {
    @IBOutlet var Text: NSTextField!
    @IBOutlet var TextConstraint: NSLayoutConstraint!
    @IBOutlet var InlineImage: InlineImageView!
    @IBOutlet var InlineImageConstraint: NSLayoutConstraint!
    @IBOutlet var Icon: ContextImageView!
    @IBOutlet var Time: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func viewWillDraw() {
        if event == nil {
            return
        }
        
        let roomId = event!.roomId
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        
        Time.stringValue = super.timestamp()
        
        let icon = super.icon()
        Icon.isHidden = !room!.state.isEncrypted
        Icon.image = icon.image
        Icon.setFrameSize(room!.state.isEncrypted ? NSMakeSize(icon.width, icon.height) : NSMakeSize(0, icon.height))
        
        var finalTextColor = NSColor.textColor
        
        if let msgtype = event!.content["msgtype"] as? String? {
            InlineImage.isHidden = ["m.emote", "m.notice", "m.text"].contains(where: { $0 == msgtype })
            Text.isHidden = !InlineImage.isHidden
            
            switch msgtype {
            case "m.image":
                if let info = event!.content["info"] as? [String: Any] {
                    let mimetype = info["mimetype"] as? String? ?? "application/octet-stream"
                    InlineImage.setImage(forMxcUrl: event!.content["url"] as? String, withMimeType: mimetype,  useCached: true)
                } else {
                    InlineImage.setImage(forMxcUrl: event!.content["url"] as? String, withMimeType: "application/octet-stream",  useCached: true)
                }
                break
            case "m.emote":
                Text.attributedStringValue = super.emoteContent(align: .left)
                break
            case "m.notice":
                finalTextColor = NSColor.headerColor
                fallthrough
            case "m.text":
                let text = super.textContent()
                if text.attributedString != nil {
                    Text.attributedStringValue = text.attributedString!
                } else if text.string != "" {
                    Text.stringValue = text.string!
                }
                break
            default:
                Text.stringValue = ""
                Text.placeholderString = "Message type '\(msgtype!)' not supported"
                break
            }
        } else {
            Text.stringValue = "No content type"
        }
        
        switch event!.sentState {
        case MXEventSentStateSending:
            Text.textColor = NSColor.gridColor
            break
        case MXEventSentStateFailed:
            if !room!.state.isEncrypted {
                Icon.isHidden = false
                Icon.setFrameSize(NSMakeSize(icon.width, icon.height))
            }
            Icon.image = NSImage(named: NSImage.Name.refreshTemplate)!.tint(with: NSColor.red)
            Icon.roomId = roomId
            Icon.eventId = event!.eventId
            // Icon = messageSendErrorHandler
            Text.textColor = NSColor.red
            break
        default:
            Text.textColor = finalTextColor
        }
        TextConstraint.constant = 48 + Icon.frame.size.width
        InlineImageConstraint.constant = 48 + Icon.frame.size.width
    }
    
}
