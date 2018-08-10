//
//  NSImage.swift
//  Seaglass
//
//  Created by Neil Alexander on 10/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

extension NSImage {
    func tint(with tintColor: NSColor) -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }
        
        return NSImage(size: size, flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            
            tintColor.set()
            context.clip(to: bounds, mask: cgImage)
            context.fill(bounds)
            
            return true
        }
    }
}
