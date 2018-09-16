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
    
    static let allowedTypes = [ "m.room.create", "m.room.message", "m.room.name", "m.room.member", "m.room.topic", "m.room.avatar", "m.room.canonical_alias", "m.sticker", "m.room.encryption" ]

    private var _managedTable: MainViewTableView?
    private var _filteredContent: [MXEvent] = []
    private var _unfilteredContent: [MXEvent] = []
    
    private let lock = DispatchSemaphore(value: 1)
    
    var managedTable: MainViewTableView? {
        get { return _managedTable }
        set {
            _managedTable = newValue
            if let table = _managedTable {
                table.reloadData()
            }
        }
    }
    
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
            ((event.isEncrypted && event.decryptionError != nil) || (!event.isRedactedEvent() && event.content.count > 0))
    }
    
    func reset(_ content: [MXEvent] = []) {
        self.unfilteredContent = content
        if let table = _managedTable {
            table.reloadData()
        }
    }
    
    func append(_ newElement: MXEvent) {
        guard !self.unfilteredContent.contains(where: { $0.eventId == newElement.eventId }) else { return }
        DispatchQueue.main.async {
            self.unfilteredContent.append(newElement)
            if let table = self._managedTable {
                if self.filter(newElement) {
                    table.beginUpdates()
                    table.noteNumberOfRowsChanged()
                    //table.insertRows(at: IndexSet([self.filteredContent.count-1]), withAnimation: [])
                    table.endUpdates()
                }
            }
        }
    }
    
    func insert(_ newElement: MXEvent, at: Int) {
        guard !self.unfilteredContent.contains(where: { $0.eventId == newElement.eventId }) else { return }
        DispatchQueue.main.async {
            self.unfilteredContent.insert(newElement, at: at)
            if let table = self._managedTable {
                if self.filter(newElement) {
                    table.beginUpdates()
                    table.insertRows(at: IndexSet([at]), withAnimation: [])
                    table.endUpdates()
                }
            }
        }
    }
    
    func replace(_ newElement: MXEvent, at: Int) {
        guard self.unfilteredContent[at].eventId == newElement.eventId else { return }
        DispatchQueue.main.async {
            if let table = self._managedTable {
                table.beginUpdates()
                if self.filter(self.unfilteredContent[at]) {
                    if let index = self.filteredContent.index(of: self.unfilteredContent[at]) {
                        table.removeRows(at: IndexSet([index]), withAnimation: [])
                    }
                }
            }
            self.unfilteredContent[at] = newElement
            if let table = self._managedTable {
                if self.filter(newElement) {
                    if let index = self.filteredContent.index(of: newElement) {
                        table.insertRows(at: IndexSet([index]), withAnimation: [])
                    }
                }
                table.endUpdates()
            }
        }
    }
    
    func remove(at: Int) {
        let rowindex = filteredContent.index(of: unfilteredContent[at])
        DispatchQueue.main.async {
            self.unfilteredContent.remove(at: at)
            if let table = self._managedTable {
                if rowindex != nil {
                    table.beginUpdates()
                    table.removeRows(at: IndexSet([rowindex!]), withAnimation: [])
                    table.endUpdates()
                }
            }
        }
    }
    
}
