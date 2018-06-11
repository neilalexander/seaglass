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
    
    func matrixDidJoinRoom(_ room: MXRoom) {
        print("MainViewRoomsController matrixDidJoinRoom \(room)")
      //  NSAnimationContext.runAnimationGroup({ context in
      //      RoomList.insertRows(at: 0, withAnimation: .EffectFade | .SlideUp)
      //  }, completionHandler: {
      //      roomCache.append(room)
      //      RoomList.reloadData()
      //  })
        roomCache.insert(room, at: 0)
        RoomList.reloadData()
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
        
        cell?.roomId = state?.roomId
        cell?.RoomListEntryName.stringValue = state?.name ?? state?.canonicalAlias ?? "Unnamed room"
        cell?.RoomListEntryTopic.stringValue = "\(state?.members.count ?? 0) members\n" + (state?.topic ?? "No topic set")
        
        MatrixServices.inst.subscribeToRoom(roomId: (state?.roomId)!)

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
