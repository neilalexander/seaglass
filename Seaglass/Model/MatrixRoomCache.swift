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

    private var _managedTable: MainViewTableView?
    private var _filteredContent: [MXEvent] = []
    private var _unfilteredContent: [MXEvent] = []
    
    private let lock = DispatchSemaphore(value: 1)
    
    var managedTable: MainViewTableView? {
        get { return _managedTable }
        set {
            _managedTable = newValue
            if let table = _managedTable {
                table.beginUpdates()
                table.reloadData()
                table.endUpdates()
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
        return !event.isRedactedEvent() && event.content.count > 0 && [ "m.room.create", "m.room.message", "m.room.name", "m.room.member", "m.room.topic", "m.room.avatar", "m.room.canonical_alias", "m.sticker", "m.room.encryption" ].contains(event.type)
    }
    
    func reset(_ content: [MXEvent] = []) {
        self.unfilteredContent = content
        if let table = _managedTable {
            table.beginUpdates()
            table.reloadData()
            table.endUpdates()
        }
    }
    
    func append(_ newElement: MXEvent) {
        guard !self.unfilteredContent.contains(where: { $0.eventId == newElement.eventId }) else { return }
        self.unfilteredContent.append(newElement)
        if let table = _managedTable {
            if self.filter(newElement) {
                table.beginUpdates()
                table.noteNumberOfRowsChanged()
                table.endUpdates()
            }
        }
    }
    
    func insert(_ newElement: MXEvent, at: Int) {
        guard !self.unfilteredContent.contains(where: { $0.eventId == newElement.eventId }) else { return }
        self.unfilteredContent.insert(newElement, at: at)
        if let table = _managedTable {
            if self.filter(newElement) {
                table.beginUpdates()
                table.noteNumberOfRowsChanged()
                table.endUpdates()
            }
        }
    }
    
    func replace(_ newElement: MXEvent, at: Int) {
        guard self.unfilteredContent[at].eventId == newElement.eventId else { return }
        if let table = _managedTable {
            table.beginUpdates()
            if filter(self.unfilteredContent[at]) {
                if let index = filteredContent.index(of: self.unfilteredContent[at]) {
                    table.removeRows(at: IndexSet([index]), withAnimation: [.effectFade, .effectGap])
                }
            }
        }
        self.unfilteredContent[at] = newElement
        if let table = _managedTable {
            if self.filter(newElement) {
                if let index = filteredContent.index(of: newElement) {
                    table.insertRows(at: IndexSet([index]), withAnimation: [.effectFade, .effectGap])
                }
            }
            table.endUpdates()
        }
    }
    
    func remove(at: Int) {
        let rowindex = filteredContent.index(of: unfilteredContent[at])
        self.unfilteredContent.remove(at: at)
        if let table = _managedTable {
            if rowindex != nil {
                table.beginUpdates()
                table.removeRows(at: IndexSet([rowindex!]), withAnimation: [.effectFade, .effectGap])
                table.endUpdates()
            }
        }
    }
    
}
