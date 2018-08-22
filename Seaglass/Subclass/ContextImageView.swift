//
//  ContextImageView.swift
//  Seaglass
//
//  Created by Neil Alexander on 22/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class ContextImageView: NSImageView {
    var handler: ((_: String?, _: String?, _: String?) -> ())?
    
    var roomId: String?
    var eventId: String?
    var userId: String?
    
    init(handler: @escaping (_: String?, _: String?, _: String?) -> ()?) {
        self.handler = handler as? ((String?, String?, String?) -> ()) ?? nil
        super.init(frame: NSRect())
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        if handler == nil {
            return
        }
        
        self.handler!(roomId, eventId, userId)
    }
}
