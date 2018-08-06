//
//  MainViewTableView.swift
//  Seaglass
//
//  Created by Neil Alexander on 10/06/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class MainViewTableView: NSTableView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func scrollRowToVisible(row: Int, animated: Bool) {
        if animated {
            guard let clipView = superview as? NSClipView,
                let _ = clipView.superview as? NSScrollView else {
                    return
            }
            
            let rowRect = rect(ofRow: row)
            var scrollOrigin = rowRect.origin
            
            let tableHalfHeight = clipView.frame.height * 0.5
            let rowRectHalfHeight = rowRect.height * 0.5
            
            scrollOrigin.y = (scrollOrigin.y - tableHalfHeight) + rowRectHalfHeight
            
            clipView.animator().setBoundsOrigin(scrollOrigin)
        } else {
            scrollRowToVisible(row)
        }
    }
    
}
