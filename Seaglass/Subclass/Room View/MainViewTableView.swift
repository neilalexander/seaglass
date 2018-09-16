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

class MainViewTableView: NSTableView {
    
    var roomId: String! = ""

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
