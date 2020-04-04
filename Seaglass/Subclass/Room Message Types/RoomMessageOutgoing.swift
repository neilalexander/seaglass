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

class RoomMessageOutgoing: RoomMessage {
    @IBOutlet var From: NSTextField!
    @IBOutlet var Text: NSTextField!
    @IBOutlet var TextConstraint: NSLayoutConstraint!
    @IBOutlet var Avatar: AvatarImageView!
    @IBOutlet var InlineImage: InlineImageView!
    @IBOutlet var InlineImageConstraint: NSLayoutConstraint!
    @IBOutlet var Icon: ContextImageView!
    @IBOutlet var Time: NSTextField!
    @IBOutlet var RequestKeys: NSButton!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func viewWillDraw() {
        guard event != nil else { return }
        guard let roomId = event!.roomId else { return }
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return }
        guard event != drawnEvent || event!.hash != drawnEventHash else {
            Avatar.setAvatar(forUserId: event!.sender)
            return
        }
        
        RequestKeys.isHidden = !super.encryptionIsPending()
        
        Text.allowsEditingTextAttributes = true
        
        From.stringValue = super.from()
        Time.stringValue = super.timestamp()
        Time.toolTip = super.timestamp(.medium, andDate: .medium)
        Avatar.setAvatar(forUserId: event!.sender)

        room.state { state in
            guard let state = state else { fatalError() }
            let icon = super.icon()
            self.Icon.isHidden = !state.isEncrypted
            self.Icon.image = icon.image
            self.Icon.setFrameSize(state.isEncrypted ? NSMakeSize(icon.width, icon.height) : NSMakeSize(0, icon.height))
        }
        
        var finalTextColor = NSColor.textColor
        
        switch event!.type {
        case "m.room.encrypted":
            Text.stringValue = ""
            Text.placeholderString = "Unable to decrypt (waiting for keys)"
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
                if !Text.isHidden {
                    Text.layer?.backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0).cgColor
                }
                
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
                    Text.attributedStringValue = super.emoteContent(align: .right)
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
                                link.addAttribute(NSAttributedString.Key.link, value: httpUrl as Any, range: NSMakeRange(0, filename.count))
                                link.setAlignment(NSTextAlignment.right, range: NSMakeRange(0, filename.count))
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
        drawnEventHash = event!.content.count
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
            room!.state { state in
                if !state!.isEncrypted {
                    self.Icon.isHidden = false
                    self.Icon.setFrameSize(NSMakeSize(icon.width, icon.height))
                }
                self.Icon.isHidden = false
                self.Icon.setFrameSize(NSMakeSize(icon.width, icon.height))
            }
            Icon.image = NSImage(named: NSImage.refreshTemplateName)!.tint(with: NSColor.red)
            break
        default:
            break
        }
        TextConstraint.constant = 48 + Icon.frame.size.width
        InlineImageConstraint.constant = 48 + Icon.frame.size.width
    }
    
    @IBAction func requestKeysPressed(_ sender: NSButton) {
        guard sender == RequestKeys && RequestKeys.isHidden == false else { return }
        
        MatrixServices.inst.session.crypto.reRequestRoomKey(for: super.event)
        
        let alert = NSAlert()
        alert.messageText = "Encryption keys requested"
        alert.informativeText = "Encryption keys have been requested from your other Matrix clients. If your device is not verified, you may see a key sharing request."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: super.window!) { (response) in
        }
    }
}
