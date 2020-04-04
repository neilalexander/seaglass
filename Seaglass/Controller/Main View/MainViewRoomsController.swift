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

class MainViewRoomsController: NSViewController, MatrixRoomsDelegate, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var RoomList: NSTableView!
    @IBOutlet var RoomSearch: NSSearchField!
    
    var mainController: MainViewController?

    @IBOutlet var roomsCacheController: NSArrayController!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        roomsCacheController.preservesSelection = true
        roomsCacheController.selectsInsertedObjects = false
        roomsCacheController.sortDescriptors = [
            NSSortDescriptor(key: "roomSortWeight", ascending: true),
            NSSortDescriptor(key: "roomName", ascending: true)
        ]
    }
    
    override func viewDidAppear() {
        for room in MatrixServices.inst.session.rooms {
            matrixDidJoinRoom(room)
        }
    }
    
    func matrixNetworkConnectivityChanged(wifi: Bool, wwan: Bool) {

    }
    
    func matrixDidJoinRoom(_ room: MXRoom) {
        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        let isFirst = rooms.count == 0
        if !matrixIsRoomKnown(room) {
            room.state {
                self.roomsCacheController.insert((RoomsCacheEntry(room: room, state: $0!)), atArrangedObjectIndex: 0)
            }
        }
        roomsCacheController.rearrangeObjects()
        MatrixServices.inst.subscribeToRoom(roomId: room.roomId)
        RoomSearch.placeholderString = "Search \(rooms.count) room"
        if rooms.count != 1 {
            RoomSearch.placeholderString?.append(contentsOf: "s")
        }
        if isFirst {
            RoomList.selectRowIndexes(IndexSet([0]), byExtendingSelection: false)
        }
    }
    
    func matrixIsRoomKnown(_ room: MXRoom) -> Bool {
        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        if rooms.count > 0 {
            return rooms.firstIndex(where: { $0.roomId == room.roomId }) != nil
        }
        return false
    }
    
    func matrixDidPartRoom(_ room: MXRoom) {
        if MatrixServices.inst.eventListeners[room.roomId] != nil {
            MatrixServices.inst.eventListeners[room.roomId] = nil
        }
        roomsCacheController.rearrangeObjects()
        let index = (roomsCacheController.arrangedObjects as! [RoomsCacheEntry]).firstIndex(where: { $0.roomId == room.roomId} )
        if index != nil {
            RoomList.beginUpdates()
            roomsCacheController.remove(atArrangedObjectIndex: index!)
            RoomList.endUpdates()
        }
        
        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        RoomSearch.placeholderString = "Search \(rooms.count) room"
        if rooms.count != 1 {
            RoomSearch.placeholderString?.append(contentsOf: "s")
        }
    }
    
    func matrixDidUpdateRoom(_ room: MXRoom) {
        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        if rooms.count == 0 {
            return
        }
        for i in 0..<rooms.count {
            if rooms[i].roomId == room.roomId {
                RoomList.reloadData(forRowIndexes: IndexSet([i]), columnIndexes: IndexSet([0]))
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (roomsCacheController.arrangedObjects as! [RoomsCacheEntry]).count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomListEntry"), owner: self) as? RoomListEntry
        
        let state: RoomsCacheEntry = (roomsCacheController.arrangedObjects as! [RoomsCacheEntry])[row]
        cell?.roomsCacheEntry = state
        cell?.RoomListEntryName.stringValue = state.roomDisplayName
        
        let count = state.members.count
    
        if state.roomAvatar == "" {
            if state.members.count == 2 {
                if state.members[0].userId == MatrixServices.inst.session.myUser.userId {
                    cell?.RoomListEntryIcon.setAvatar(forUserId: state.members[1].userId)
                } else {
                    cell?.RoomListEntryIcon.setAvatar(forUserId: state.members[0].userId)
                }
            } else if state.members.count == 1 {
                cell?.RoomListEntryIcon.setAvatar(forUserId: state.members[0].userId)
            } else {
                cell?.RoomListEntryIcon.setAvatar(forText: state.roomDisplayName)
            }
        } else {
            cell?.RoomListEntryIcon.setAvatar(forRoomId: state.roomId)
        }

        var unreadColor = NSColor(calibratedRed: 0.51, green: 0.61, blue: 0.95, alpha: 1.00)
        if state.isInvite() {
            unreadColor = NSColor(calibratedRed: 0.90, green: 0.35, blue: 0.29, alpha: 1.00)
            cell?.RoomListEntryTopic.stringValue = "Room invite"
            cell?.RoomListEntryUnread.isHidden = false
        } else {
            switch AppDefaults.shared.showMostRecentMessageInSidebar {
                case false:
                    var memberString: String = ""
                    var topicString: String = "No topic set"
                    
                    if state.roomTopic != "" {
                        topicString = state.roomTopic
                    }
                    
                    switch count {
                        case 0: fallthrough
                        case 1: memberString = "Empty room"; break
                        case 2: memberString = "Direct chat"; break
                        default: memberString = "\(count) members"
                    }
                    
                    cell?.RoomListEntryTopic.stringValue = "\(memberString)\n\(topicString)"
                    break
                case true:
                    let lastMessagePreview: String = state.room.summary.lastMessageEvent?.content["body"] as? String ?? ""
                    cell?.RoomListEntryTopic.cell?.truncatesLastVisibleLine = true
                    cell?.RoomListEntryTopic.stringValue = lastMessagePreview
                    break
            }
            
            cell?.RoomListEntryUnread.image? = (cell?.RoomListEntryUnread.image?.tint(with: NSColor.blue))!
            if tableView.selectedRow != row {
                cell?.RoomListEntryUnread.isHidden = !state.unread()
            } else {
                cell?.RoomListEntryUnread.isHidden = true
            }
        }
        cell?.RoomListEntryUnread.image? = (cell?.RoomListEntryUnread.image?.tint(with: unreadColor))!
        
        cell?.identifier = nil
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let row = notification.object as? NSTableView else { return }
        let roomsCache = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        if row.selectedRow < 0 || row.selectedRow >= (roomsCacheController.arrangedObjects as! [RoomsCacheEntry]).count {
            return
        }
        guard let entry = row.view(atColumn: 0, row: row.selectedRow, makeIfNecessary: false) as? RoomListEntry else { return }
        if entry.roomsCacheEntry == nil {
            return
        }
        if roomsCache.firstIndex(where: { $0.roomId == entry.roomsCacheEntry!.roomId }) == nil {
            return
        }
        entry.RoomListEntryUnread.isHidden = !entry.roomsCacheEntry!.isInvite()
        self.mainController?.channelDelegate?.uiDidSelectRoom(entry: entry)
    }
    
    func updateAttentionRooms() {
        let roomsCache = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        var count = roomsCache.filter({ $0.isInvite() }).count
       /* for room in roomsCache {
            count += room.highlights()
        } */
        NSApp.dockTile.badgeLabel = count > 0 ? String(count) : ""
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
       // updateAttentionRooms()
    }
    
    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
       // updateAttentionRooms()
    }
    
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        let roomCacheEntry = (self.roomsCacheController.arrangedObjects as! [RoomsCacheEntry])[row]
        let roomId = roomCacheEntry.roomId
        if edge == .trailing {
            let label = roomCacheEntry.isInvite() ? "Decline" : "Leave"
            return [
                NSTableViewRowAction(style: .destructive, title: label, handler: { (action, row) in
                    tableView.removeRows(at: IndexSet(integer: row), withAnimation: [.slideUp, .effectFade])
                    self.roomsCacheController.remove(atArrangedObjectIndex: row)
                    MatrixServices.inst.session.leaveRoom(roomId) { (response) in
                        if response.isFailure, let error = response.error {
                            tableView.insertRows(at: IndexSet(integer: row), withAnimation: [.slideDown, .effectFade])
                            let alert = NSAlert()
                            alert.messageText = "Failed to leave room \(roomId)"
                            alert.informativeText = error.localizedDescription
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            )]
        } else {
            return []
        }
    }
}
