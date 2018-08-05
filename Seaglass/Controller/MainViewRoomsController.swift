//
// Seaglass, a native macOS Matrix client
// Copyright © 2018, Neil Alexander
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Cocoa
import SwiftMatrixSDK

class RoomListEntry: NSTableCellView {
    @IBOutlet var RoomListEntryName: NSTextField!
    @IBOutlet var RoomListEntryTopic: NSTextField!
    @IBOutlet var RoomListEntryIcon: NSImageView!
    @IBOutlet var RoomListEntryUnread: NSImageView!
    
    
    
    var roomsCacheEntry: RoomsCacheEntry?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class MainViewRoomsController: NSViewController, MatrixRoomsDelegate, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet var RoomList: NSTableView!
    @IBOutlet var ConnectionStatus: NSButton!
    
    var mainController: MainViewController?
    
    @IBOutlet var roomsCacheController: NSArrayController!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
    //    roomsCacheController.sortDescriptors.append(NSSortDescriptor(key: "self.RoomListEntryUnread.isHidden", ascending: true))
    //    roomsCacheController.sortDescriptors.append(NSSortDescriptor(key: "self.RoomListEntryName.stringValue", ascending: true))
    //    roomsCacheController.didChangeArrangementCriteria()
        
        switch MatrixServices.inst.state {
        case .started:
            ConnectionStatus.image? = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))!
            ConnectionStatus.title = "Connected"
        case .starting:
            ConnectionStatus.image? = NSImage(named: NSImage.Name(rawValue: "NSStatusPartiallyAvailable"))!
            ConnectionStatus.title = "Connecting..."
        default:
            ConnectionStatus.image? = NSImage(named: NSImage.Name(rawValue: "NSStatusUnavailable"))!
            ConnectionStatus.title = "Not connected"
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
    }
    
    func matrixDidPartRoom(_ room: MXRoom) {
        // TODO: unsubscribe from room
    }
    
    func matrixDidUpdateRoom(_ room: MXRoom) {

        let rooms = roomsCacheController.arrangedObjects as! [RoomsCacheEntry]
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
        
        cell?.RoomListEntryUnread.isHidden = MatrixServices.inst.session.room(withRoomId: state.roomId).summary.localUnreadEventCount == 0
        
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
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = notification.object as! NSTableView
        
        if row.selectedRow < 0 {
            return
        }
        
        let entry = row.view(atColumn: 0, row: row.selectedRow, makeIfNecessary: true) as! RoomListEntry
        // let state: RoomsCacheEntry = (roomsCacheController.arrangedObjects as! [RoomsCacheEntry])[row.selectedRow]
        
        // MatrixServices.inst.session.room(withRoomId: state.roomId).markAllAsRead()
        entry.RoomListEntryUnread.isHidden = true
        
        DispatchQueue.main.async {
            self.mainController?.channelDelegate?.uiDidSelectRoom(entry: entry)
        }
    }
}
