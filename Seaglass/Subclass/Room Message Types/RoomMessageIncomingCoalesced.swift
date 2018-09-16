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
        guard event != nil else { return }
        guard let roomId = event!.roomId else { return }
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return }
        guard event != drawnEvent else { return }
        
        Time.stringValue = super.timestamp()
        Time.toolTip = super.timestamp(.medium, andDate: .medium)
        
        let icon = super.icon()
        Icon.isHidden = !room.state.isEncrypted
        Icon.image = icon.image
        Icon.setFrameSize(room.state.isEncrypted ? NSMakeSize(icon.width, icon.height) : NSMakeSize(0, icon.height))
        
        var finalTextColor = NSColor.textColor
        let displayname = MatrixServices.inst.session.myUser.displayname ?? MatrixServices.inst.session.myUser.userId
        
        switch event!.type {
        case "m.room.encrypted":
            Text.stringValue = ""
            if event!.decryptionError != nil {
                Text.placeholderString = event!.decryptionError.localizedDescription
            } else {
                Text.placeholderString = "Encrypted event"
            }
            break
        case "m.sticker":
            if let info = event!.content["info"] as? [String: Any] {
                if let thumbnailUrl = info["thumbnail_url"] as? String {
                    let mimetype = info["mimetype"] as? String? ?? "application/octet-stream"
                    InlineImage.setImage(forMxcUrl: thumbnailUrl, withMimeType: mimetype, useCached: true, enableQuickLook: false)
                    InlineImage.isHidden = false
                } else {
                    Text.stringValue = event!.content["body"] as? String ?? "Sticker failed to load"
                    InlineImage.isHidden = true
                }
                Text.isHidden = !InlineImage.isHidden
            }
            break
        default:
            if let msgtype = event!.content["msgtype"] as? String? {
                InlineImage.isHidden = ["m.emote", "m.notice", "m.text"].contains(where: { $0 == msgtype })
                if InlineImage.isHidden {
                    InlineImage.resetImage()
                }
                Text.isHidden = !InlineImage.isHidden
                Text.layer?.cornerRadius = 6
                Text.wantsLayer = true
                
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
                    InlineImage.isHidden = true
                    Text.isHidden = false
                    if event!.isMediaAttachment() {
                        if let filename = event?.content["filename"] as? String ?? event?.content["body"] as? String {
                            if let mxcUrl = event!.content["url"] as? String {
                                let httpUrl = MatrixServices.inst.client.url(ofContent: mxcUrl)
                                let link: NSMutableAttributedString = NSMutableAttributedString(string: filename)
                                link.addAttribute(NSAttributedStringKey.link, value: httpUrl as Any, range: NSMakeRange(0, filename.count))
                                link.setAlignment(NSTextAlignment.left, range: NSMakeRange(0, filename.count))
                                Text.attributedStringValue = link
                            } else {
                                Text.placeholderString = filename
                            }
                        } else {
                            Text.placeholderString = "Unnamed attachment"
                        }
                    } else {
                        Text.placeholderString = "Message type '\(msgtype ?? "(none)")' not supported"
                    }
                    break
                }
                if Text.stringValue.contains(displayname!) || Text.attributedStringValue.string.contains(displayname!) {
                    Text.layer?.backgroundColor = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.15).cgColor
                } else {
                    Text.layer?.backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0).cgColor
                }
            } else {
                Text.stringValue = "No content type"
            }
        }
        
        switch event!.sentState {
        case MXEventSentStateSending:
            Text.textColor = NSColor.gridColor
            break
        case MXEventSentStateFailed:
            Text.textColor = NSColor.red
            break
        default:
            Text.textColor = finalTextColor
        }
        
        self.updateIcon()
        drawnEvent = event
    }
    
    override func updateIcon() {
        if event == nil {
            return
        }
        
        let roomId = event!.roomId
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        let icon = super.icon()
        
        Icon.room = room
        Icon.event = event!
        switch event!.sentState {
        case MXEventSentStateFailed:
            if !room!.state.isEncrypted {
                Icon.isHidden = false
                Icon.setFrameSize(NSMakeSize(icon.width, icon.height))
            }
            Icon.image = NSImage(named: NSImage.Name.refreshTemplate)!.tint(with: NSColor.red)
            break
        default:
            break
        }
        TextConstraint.constant = 48 + Icon.frame.size.width
        InlineImageConstraint.constant = 48 + Icon.frame.size.width
    }
    
}
