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

class ChannelMessageEntry: NSTableCellView {
    @IBOutlet var ChannelMessageEntryInboundFrom: NSTextField!
    @IBOutlet var ChannelMessageEntryInboundText: NSTextField!
    @IBOutlet var ChannelMessageEntryInboundIcon: NSImageView!
    
    @IBOutlet var ChannelMessageEntryOutboundFrom: NSTextField!
    @IBOutlet var ChannelMessageEntryOutboundText: NSTextField!
    @IBOutlet var ChannelMessageEntryOutboundIcon: NSImageView!
    
    @IBOutlet var ChannelMessageEntryInlineText: NSTextField!
}

class MainViewChannelController: NSViewController, MatrixChannelDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet var ChannelName: NSTokenField!
    @IBOutlet var ChannelMessageInput: NSTextField!
    @IBOutlet var ChannelMessageScrollView: NSScrollView!
    @IBOutlet var ChannelMessageTableView: NSTableView!
    @IBOutlet var ChannelInfoButton: NSButton!
    @IBOutlet var ChannelPartButton: NSButton!
    @IBOutlet var ChannelInsertButton: NSButton!
    
    weak public var mainController: MainViewController?
    
    var roomId: String = ""
    
    // <roomID, [MXEvent]>
    var eventCache: Dictionary<String, [MXEvent]> = [:]
    
    @IBAction func messageEntryFieldSubmit(_ sender: NSTextField) {
        if roomId == "" {
            return
        }
        
        sender.isEnabled = false
        
        MatrixServices.inst.client?.sendTextMessage(toRoom: roomId, text: sender.stringValue) { (response) in
            if case .success( _) = response {
                sender.stringValue = ""
            }
            sender.isEnabled = true
            sender.becomeFirstResponder()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if roomId == "" || eventCache[roomId] == nil {
            return 0
        }
        return (eventCache[roomId]?.count)!
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let event = eventCache[roomId]![row]
        
        switch event.type {
        case "m.room.message":
            if event.sender == MatrixServices.inst.client?.credentials.userId {
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChannelMessageEntryOutbound"), owner: self) as? ChannelMessageEntry
                if event.content["body"] != nil {
                    cell?.ChannelMessageEntryOutboundText.stringValue = event.content["body"] as! String
                    cell?.ChannelMessageEntryOutboundFrom.stringValue = event.sender as String
                }
                return cell
            } else {
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChannelMessageEntryInbound"), owner: self) as? ChannelMessageEntry
                if event.content["body"] != nil {
                    cell?.ChannelMessageEntryInboundText.stringValue = event.content["body"] as! String
                    cell?.ChannelMessageEntryInboundFrom.stringValue = event.sender as String
                }
                return cell
            }
        case "m.room.member":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChannelMessageEntryInline"), owner: self) as? ChannelMessageEntry
            switch event.content["membership"] as! String {
            case "join":
                cell?.ChannelMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) joined the room"
                break
            case "leave":
                cell?.ChannelMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) left the room"
                break
            case "invite":
                cell?.ChannelMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) was invited to the room"
                break
            case "ban":
                cell?.ChannelMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) was banned from the room"
                break
            default:
                cell?.ChannelMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) unknown event: \(event.stateKey)"
                break
            }
            return cell
        default:
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChannelMessageEntryInline"), owner: self) as? ChannelMessageEntry
            cell?.ChannelMessageEntryInlineText.stringValue = "Unknown event \(event.type)"
            return cell
        }
    }
    
    func uiDidSelectChannel(entry: ChannelListEntry) {
        ChannelName.isEnabled = true
        ChannelInfoButton.isEnabled = true
        ChannelPartButton.isEnabled = true
        ChannelInsertButton.isEnabled = true
        ChannelMessageInput.isEnabled = true

        ChannelName.stringValue = entry.ChannelListEntryName.stringValue
        
        roomId = entry.roomId!
        MatrixServices.inst.selectRoom(roomId: entry.roomId!)

        ChannelMessageTableView.reloadData()
    }
    
    func matrixDidChannelMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState) {
        if event.roomId == nil {
            return
        }
        if eventCache[event.roomId] == nil {
            eventCache[event.roomId] = []
        }
        if eventCache[event.roomId]?.last == event || eventCache[event.roomId]?.first == event {
            // duplicate event?
            return
        }
        switch event.type {
        case "m.room.message":
            if event.content["body"] == nil {
                return
            }
            fallthrough
        case "m.room.member":
            switch direction {
            case .forwards:
                eventCache[event.roomId]?.append(event)
                break
            default:
                eventCache[event.roomId]?.insert(event, at: 0)
                break
            }
            if event.roomId == roomId {
                ChannelMessageTableView.reloadData()
                let height = ChannelMessageScrollView.documentView!.frame.size.height
                ChannelMessageScrollView.contentView.scroll(NSPoint(x: 0, y: height))
            }
            return
        default:
            break
        }
    }
    func matrixDidChannelUserJoin() {}
    func martixDidChannelUserPart() {}
    
}
