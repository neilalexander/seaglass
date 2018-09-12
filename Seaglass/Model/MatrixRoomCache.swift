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
            _filteredContent = _unfilteredContent.filter(filter)
        }
    }
    
    dynamic var filteredContent: [MXEvent] {
        get { return _filteredContent }
    }
    
    var filter = { (event: MXEvent) -> Bool in
        return !event.isRedactedEvent() && event.content.count > 0 && [ "m.room.create", "m.room.message", "m.room.name", "m.room.member", "m.room.topic", "m.room.avatar", "m.room.canonical_alias", "m.sticker", "m.room.encryption" ].contains(event.type)
    }
    
    func reset(_ content: [MXEvent] = []) {
        self.unfilteredContent = content
        if let table = _managedTable {
            table.reloadData()
        }
    }
    
    func append(_ newElement: MXEvent) {
        self.unfilteredContent.append(newElement)
        if let table = _managedTable {
            if self.filter(newElement) {
                table.noteNumberOfRowsChanged()
            }
        }
    }
    
    func insert(_ newElement: MXEvent, at: Int) {
        self.unfilteredContent.insert(newElement, at: at)
        if let table = _managedTable {
            if self.filter(newElement) {
                if let index = filteredContent.index(of: newElement) {
                    table.insertRows(at: IndexSet([index]), withAnimation: [.slideDown, .effectFade])
                }
            }
        }
    }
    
    func replace(_ newElement: MXEvent, at: Int) {
        if let table = _managedTable {
            if filter(self.unfilteredContent[at]) {
                if let index = filteredContent.index(of: self.unfilteredContent[at]) {
                    table.removeRows(at: IndexSet([index]), withAnimation: [.effectFade])
                }
            }
        }
        self.unfilteredContent[at] = newElement
        if let table = _managedTable {
            if self.filter(newElement) {
                if let index = filteredContent.index(of: newElement) {
                    table.insertRows(at: IndexSet([index]), withAnimation: .effectFade)
                }
            }
        }
    }
    
    func remove(at: Int) {
        let rowindex = filteredContent.index(of: unfilteredContent[at])
        self.unfilteredContent.remove(at: at)
        if let table = _managedTable {
            if rowindex != nil {
                table.removeRows(at: IndexSet([rowindex!]), withAnimation: .effectFade)
            }
        }
    }
    
}
