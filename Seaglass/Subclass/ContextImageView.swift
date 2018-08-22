//
//  ContextImageView.swift
//  Seaglass
//
//  Created by Neil Alexander on 22/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class ContextImageView: NSImageView {
    enum ContextType {
        case encryptedEvent
        case sendFailed
    }
    
    public var roomId: String?
    public var eventId: String?
    public var contextType: ContextType?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        if contextType == nil {
            return
        }
        
        switch contextType {
        case .encryptedEvent?:
            if roomId == nil || eventId == nil {
                return
            }
            print("Encrypted event")
            break
        case .sendFailed?:
            if roomId == nil || eventId == nil {
                return
            }
            print("Send failed for \(eventId) in \(roomId)")
            break
        default:
            break
        }
    }
}
