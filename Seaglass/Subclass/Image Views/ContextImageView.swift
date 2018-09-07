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

class ContextImageView: NSImageView {
    var handler: ((_: NSView, _: MXRoom?, _: MXEvent?, _: String?) -> ())?
    
    var room: MXRoom?
    var event: MXEvent?
    var userId: String?
    
    init(handler: @escaping (_: NSView, _: MXRoom?, _: MXEvent?, _: String?) -> ()?) {
        self.handler = handler as? ((NSView, MXRoom?, _: MXEvent?, String?) -> ()) ?? nil
        super.init(frame: NSRect())
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func mouseDown(with nsevent: NSEvent) {
        guard handler != nil else { return }
        guard !self.isHidden else { return }

        self.handler!(self, room, event, userId)
    }
}
