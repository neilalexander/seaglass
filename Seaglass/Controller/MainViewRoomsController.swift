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
    @IBOutlet var ConnectionStatus: NSButton!

    var mainController: MainViewController?

    @IBOutlet var roomsCacheController: NSArrayController!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        switch MatrixServices.inst.state {
        case .started:
            ConnectionStatus.title = MatrixServices.inst.session.myUser.userId
            ConnectionStatus.alphaValue = 0.2
        case .starting:
            ConnectionStatus.title = "Authenticating..."
            ConnectionStatus.alphaValue = 1
        default:
            ConnectionStatus.title = "Not authenticated"
            ConnectionStatus.alphaValue = 1
        }
    }
    
    override func viewDidAppear() {
        for room in MatrixServices.inst.session.rooms {
            self.matrixDidJoinRoom(room)
        }
    }
    
    func matrixDidJoinRoom(_ room: MXRoom) {
        roomsCacheController.insert(RoomsCacheEntry(room), atArrangedObjectIndex: 0)
        MatrixServices.inst.subscribeToRoom(roomId: room.roomId)
        
        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        RoomSearch.placeholderString = "Search \(rooms.count) room"
        if rooms.count != 1 {
            RoomSearch.placeholderString?.append(contentsOf: "s")
        }
    }
    
    func matrixDidPartRoom(_ room: MXRoom) {
        // TODO: unsubscribe from room
        
        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        RoomSearch.placeholderString = "Search \(rooms.count) room"
        if rooms.count != 1 {
            RoomSearch.placeholderString?.append(contentsOf: "s")
        }
    }
    
    func matrixDidUpdateRoom(_ room: MXRoom) {
        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
        for i in 0..<rooms.count {
            if rooms[i].roomId == room.roomId {
                rooms[i].roomName = room.state.name
                rooms[i].roomTopic = room.state.topic
                rooms[i].roomAlias = room.state.canonicalAlias
                RoomList.reloadData(forRowIndexes: IndexSet([i]), columnIndexes: IndexSet([0]))
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (roomsCacheController.arrangedObjects as! [RoomsCacheEntry]).count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomListEntry"), owner: self) as? RoomListEntry
        cell?.identifier = nil
        
        let state: RoomsCacheEntry = (roomsCacheController.arrangedObjects as! [RoomsCacheEntry])[row]
        cell?.roomsCacheEntry = state
    
        let count = state.members().count

        if state.roomName != "" {
            cell?.RoomListEntryName.stringValue = state.roomName
        } else if state.roomAlias != "" {
            cell?.RoomListEntryName.stringValue = state.roomAlias
        } else {
            var memberNames: String = ""
            for m in 0..<count {
                if state.members()[m].userId == MatrixServices.inst.client?.credentials.userId {
                    continue
                }
                memberNames.append(state.members()[m].displayname ?? (state.members()[m].userId)!)
                if m < count-2 {
                    memberNames.append(", ")
                }
            }
            cell?.RoomListEntryName.stringValue = memberNames
        }
        
        if state.members().count == 2 {
            if state.members()[0].userId == MatrixServices.inst.session.myUser.userId {
                cell?.RoomListEntryIcon.setAvatar(forUserId: state.members()[1].userId)
            } else {
                cell?.RoomListEntryIcon.setAvatar(forUserId: state.members()[0].userId)
            }
        } else {
            cell?.RoomListEntryIcon.setAvatar(forRoomId: state.roomId)
        }
        
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
        
        if tableView.selectedRow != row {
            cell?.RoomListEntryUnread.isHidden = !state.unread()
        }
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = notification.object as! NSTableView
        
        if row.selectedRow < 0 {
            return
        }
        
        let entry = row.view(atColumn: 0, row: row.selectedRow, makeIfNecessary: true) as! RoomListEntry
        entry.RoomListEntryUnread.isHidden = true
        
        DispatchQueue.main.async {
            self.mainController?.channelDelegate?.uiDidSelectRoom(entry: entry)
        }
    }
}
