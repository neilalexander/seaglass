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
    
    static let allowedTypes = [ "m.room.create", "m.room.message", "m.room.name", "m.room.member", "m.room.topic", "m.room.avatar", "m.room.canonical_alias", "m.sticker", "m.room.encryption", "m.room.encrypted" ]

    private var _filteredContent: [MXEvent] = []
    private var _unfilteredContent: [MXEvent] = []
    
    private let lock = DispatchSemaphore(value: 1)
    
    @objc dynamic var unfilteredContent: [MXEvent] {
        get { return _unfilteredContent }
        set {
            _unfilteredContent = newValue
            
            lock.wait()
            _filteredContent = _unfilteredContent.filter(filter)
            lock.signal()
        }
    }
    
    dynamic var filteredContent: [MXEvent] {
        get {
            lock.wait()
            defer { lock.signal() }
            return _filteredContent
        }
    }
    
    var filter = { (event: MXEvent) -> Bool in
        return MatrixRoomCache.allowedTypes.contains(event.type) &&
            ((event.isState() && !NSDictionary(dictionary: event.content).isEqual(to: event.prevContent)) || !event.isState()) &&
            !event.isRedactedEvent()
    }
    
    func reset(_ content: [MXEvent] = []) {
        self.unfilteredContent = content
        // TODO: call room delegate
    }
    
    func append(_ newElement: MXEvent) {
        guard !self.unfilteredContent.contains(where: { $0.eventId == newElement.eventId }) else { return }
        DispatchQueue.main.async {
            self.unfilteredContent.append(newElement)
            if self.filter(newElement) {
                // TODO: call room delegate
            }
        }
    }
    
    func insert(_ newElement: MXEvent, at: Int) {
        guard !self.unfilteredContent.contains(where: { $0.eventId == newElement.eventId }) else { return }
        DispatchQueue.main.async {
            self.unfilteredContent.insert(newElement, at: at)
            if self.filter(newElement) {
                // TODO: call room delegate
            }
        }
    }
    
    func replace(_ newElement: MXEvent, at: Int) {
        guard self.unfilteredContent[at].eventId == newElement.eventId else { return }
        DispatchQueue.main.async {
            if self.filter(self.unfilteredContent[at]) {
                if let index = self.filteredContent.firstIndex(of: self.unfilteredContent[at]) {
                    // TODO: call room delegate
                }
            }
            self.unfilteredContent[at] = newElement
            if self.filter(newElement) {
                if let index = self.filteredContent.firstIndex(of: newElement) {
                    // TODO: call room delegate
                }
            }
        }
    }
    
    func update(_ newElement: MXEvent) {
        guard self.unfilteredContent.contains(where: { $0.eventId == newElement.eventId }) else { return }
        if let at = self.unfilteredContent.firstIndex(where: { $0.eventId == newElement.eventId }) {
            self.replace(newElement, at: at)
        }
    }
    
    func remove(at: Int) {
        let rowindex = filteredContent.firstIndex(of: unfilteredContent[at])
        DispatchQueue.main.async {
            self.unfilteredContent.remove(at: at)
            // TODO: call room delegate
        }
    }
    
}
