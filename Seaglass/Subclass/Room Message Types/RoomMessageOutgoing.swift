//
//  MessageIncoming.swift
//  Seaglass
//
//  Created by Neil Alexander on 24/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

class RoomMessageOutgoing: RoomMessage {
    @IBOutlet var From: NSTextField!
    @IBOutlet var Text: NSTextField!
    @IBOutlet var TextConstraint: NSLayoutConstraint!
    @IBOutlet var Avatar: AvatarImageView!
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
        
        let text = super.textContent()
        let icon = super.icon()
        
        From.stringValue = super.from()
        Avatar.setAvatar(forUserId: event!.sender)
        if text.attributedString != nil {
            Text.attributedStringValue = text.attributedString!
        } else if text.string != "" {
            Text.stringValue = text.string!
        }
        Icon.isHidden = !room!.state.isEncrypted
        Icon.image = icon.image
        Icon.setFrameSize(room!.state.isEncrypted ? NSMakeSize(icon.width, icon.height) : NSMakeSize(0, icon.height))
        Time.stringValue = super.timestamp()
        
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
            Text.textColor = NSColor.textColor
        }
        TextConstraint.constant -= icon.width - Icon.frame.size.width
    }
}
