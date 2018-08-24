//
//  RoomMessage.swift
//  Seaglass
//
//  Created by Neil Alexander on 24/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

class RoomMessage: NSTableCellView {
    var event: MXEvent?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func viewWillDraw() {
    }
    
    func icon() -> (image: NSImage, width: CGFloat, height: CGFloat) {
        let padlockWidth: CGFloat = 16
        let padlockHeight: CGFloat = 12
        let padlockColor: NSColor = event!.sentState == MXEventSentStateEncrypting || event!.isEncrypted ?
            NSColor(deviceRed: 0.38, green: 0.65, blue: 0.53, alpha: 0.75) :
            NSColor(deviceRed: 0.79, green: 0.31, blue: 0.27, alpha: 0.75)
        let padlockImage: NSImage = event!.sentState == MXEventSentStateEncrypting || event!.isEncrypted ?
            NSImage(named: NSImage.Name.lockLockedTemplate)!.tint(with: padlockColor) :
            NSImage(named: NSImage.Name.lockUnlockedTemplate)!.tint(with: padlockColor)
        return (padlockImage, padlockWidth, padlockHeight)
    }
    
    func from() -> String {
        if event == nil {
            return ""
        }
        if let room = MatrixServices.inst.session.room(withRoomId: event!.roomId) {
            return room.state.memberName(event!.sender) ?? event!.sender as String
        }
        return ""
    }
    
    func timestamp() -> String {
        if event == nil {
            return "XX:XX"
        }
        
        let eventTime = Date(timeIntervalSince1970: TimeInterval(event!.originServerTs / 1000))
        let eventTimeFormatter = DateFormatter()
        eventTimeFormatter.timeZone = TimeZone.current
        eventTimeFormatter.dateFormat = "HH:mm"
        
        return eventTimeFormatter.string(from: eventTime)
    }
    
    func textContent() -> (string: String?, attributedString: NSAttributedString?) {
        if event == nil {
            return (nil, nil)
        }
        
        var cellAttributedStringValue: NSAttributedString? = nil
        var cellStringValue: String? = nil
        
        // if event.content["formatted_body"] != nil {
        //     let justification = event.sender == MatrixServices.inst.client?.credentials.userId ? NSTextAlignment.right : NSTextAlignment.left
        //     cellAttributedStringValue = (event.content["formatted_body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).toAttributedStringFromHTML(justify: justification)
        //     cellStringValue = (event.content["formatted_body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
        // } else if event.content["body"] != nil {
        //     cellStringValue = (event.content["body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
        // }
        
        if event!.content["body"] != nil {
            let justification = event!.sender == MatrixServices.inst.client?.credentials.userId ? NSTextAlignment.right : NSTextAlignment.left
            cellAttributedStringValue = (event!.content["body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).toAttributedStringFromMarkdown(justify: justification)
        }
        
        return (cellStringValue, cellAttributedStringValue)
    }
}
