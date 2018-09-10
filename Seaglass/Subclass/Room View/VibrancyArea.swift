//
//  VibrancyBox.swift
//  Seaglass
//
//  Created by Neil Alexander on 10/09/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class VibrancyArea: NSVisualEffectView {
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.blendingMode = .withinWindow
    }

    override func draw(_ dirtyRect: NSRect) {
        self.blendingMode = .withinWindow
        super.draw(dirtyRect)
    }
    
}
