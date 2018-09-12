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

@objcMembers class MatrixRoomCache: NSObject {
/*
    override func addObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], context: UnsafeMutableRawPointer?) {
        print("New observer for \(keyPath)")
        super.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("Observe value for \(keyPath ?? "no path")")
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  */
    @objc dynamic var unfilteredContent: [MXEvent] = [] {
        willSet {
            self.willChangeValue(forKey: "unfilteredContent")
            self.willChangeValue(forKey: "filteredContent")
        }
        didSet {
            self.didChangeValue(forKey: "unfilteredContent")
            self.didChangeValue(forKey: "filteredContent")
        }
    }
    
    dynamic var filteredContent: [MXEvent] {
        get { return self.unfilteredContent.filter(filter) }
    }
    
    var filter = { (event: MXEvent) -> Bool in
        return !event.isRedactedEvent() && event.content.count > 0
    }
    
    func reset() {
        self.unfilteredContent = []
    }
    
    func append(_ newElement: MXEvent) {
        self.unfilteredContent.append(newElement)
    }
    
    func insert(_ newElement: MXEvent, at: Int) {
        self.unfilteredContent.insert(newElement, at: at)
    }
    
    func replace(_ newElement: MXEvent, at: Int) {
        self.unfilteredContent[at] = newElement
    }
    
    func remove(at: Int) {
        self.unfilteredContent.remove(at: at)
    }
    
}
