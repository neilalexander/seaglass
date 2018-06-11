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
    
    var roomId: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class MainViewRoomsController: NSViewController, MatrixRoomsDelegate, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var RoomList: NSTableView!
    @IBOutlet weak var ConnectionStatus: NSButton!
    
    weak var mainController: MainViewController?
    
    var roomCache = [MXRoom]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

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
        print("MainViewRoomsController matrixDidJoinRoom \(room)")
        roomCache.insert(room, at: 0)
        NSAnimationContext.runAnimationGroup({ context in
            RoomList.insertRows(at: IndexSet.init(integer: 0), withAnimation: [ .slideUp, .effectFade ])
        }, completionHandler: {
            MatrixServices.inst.subscribeToRoom(roomId: room.roomId)
        })
    }
    
    func matrixDidPartRoom() {
        print("MainViewRoomsController matrixDidPartRoom")
        
        
    }
    
    func matrixDidUpdateRoom() {
        print("MainViewRoomsController matrixDidUpdateRoom")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return roomCache.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomListEntry"), owner: self) as? RoomListEntry
        let state = roomCache[row].state
        let count = state?.members.count ?? 0
        
        cell?.roomId = state?.roomId

        if state?.name != nil {
            cell?.RoomListEntryName.stringValue = (state?.name)!
        } else if state?.canonicalAlias != nil {
            cell?.RoomListEntryName.stringValue = (state?.canonicalAlias)!
        } else {
            var memberNames: String = ""
            for m in 0..<count {
                if state?.members[m].userId == MatrixServices.inst.client?.credentials.userId {
                    continue
                }
                memberNames.append(state?.members[m].displayname ?? (state?.members[m].userId)!)
                if m < count-2 {
                    memberNames.append(", ")
                }
            }
            cell?.RoomListEntryName.stringValue = memberNames
        }
        
        var memberString: String = ""
        var topicString: String = "No topic set"
        
        if state?.topic != nil {
            topicString = (state?.topic)!
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
        
        let entry = row.view(atColumn: 0, row: row.selectedRow, makeIfNecessary: true) as! RoomListEntry
        
        DispatchQueue.main.async {
            self.mainController?.channelDelegate?.uiDidSelectRoom(entry: entry)
        }
    }
}
