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
import Down

class RoomMessageEntry: NSTableCellView {
    @IBOutlet var RoomMessageEntryInboundFrom: NSTextField!
    @IBOutlet var RoomMessageEntryInboundText: NSTextField!
    @IBOutlet var RoomMessageEntryInboundIcon: NSImageView!
    
    @IBOutlet var RoomMessageEntryOutboundFrom: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundText: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundIcon: NSImageView!
    
    @IBOutlet var RoomMessageEntryInlineText: NSTextField!
}

extension String {
    func toAttributedStringFromHTML(justify: NSTextAlignment) -> NSAttributedString{
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            let str: NSMutableAttributedString = try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html,
                 .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            let range = NSRange(location: 0, length: str.length)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = justify
            
            str.beginEditing()
            str.removeAttribute(.paragraphStyle, range: range)
            
            str.enumerateAttributes(in: range, options: [], using: { attr, attrRange, _ in
                if let font = attr[.font] as? NSFont {
                    if font.familyName == "Times" {
                        let newFont = NSFontManager.shared.convert(font, toFamily: NSFont.systemFont(ofSize: NSFont.systemFontSize).familyName!)
                        str.addAttribute(.font, value: newFont, range: attrRange)
                    }
                }
            })
            
            str.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            str.endEditing()
            
            return str
        } catch {
            return NSAttributedString()
        }
    }
}

class MainViewRoomController: NSViewController, MatrixRoomDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet var RoomName: NSTokenField!
    @IBOutlet var RoomTopic: NSTextField!
    @IBOutlet var RoomMessageInput: NSTextField!
    @IBOutlet var RoomMessageScrollView: NSScrollView!
    @IBOutlet var RoomMessageTableView: MainViewTableView!
    @IBOutlet var RoomInfoButton: NSButton!
    @IBOutlet var RoomPartButton: NSButton!
    @IBOutlet var RoomInsertButton: NSButton!
    
    weak public var mainController: MainViewController?
    
    var roomId: String = ""

    @IBAction func messageEntryFieldSubmit(_ sender: NSTextField) {
        if roomId == "" {
            return
        }
        
        sender.isEnabled = false
        
        var formattedText: String
        let options = DownOptions(rawValue: 1 << 3)
        do {
            // TODO: Make sure this is suitably sanitised
            formattedText = try Down(markdownString: sender.stringValue).toHTML(options)
           // print(formattedText)
        } catch {
            formattedText = sender.stringValue
        }

        var returnedEvent: MXEvent?
        MatrixServices.inst.session.room(withRoomId: roomId).sendTextMessage(sender.stringValue, formattedText: formattedText, localEcho: &returnedEvent) { (response) in
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
        if !MatrixServices.inst.eventCache.keys.contains(roomId) {
            return 0
        }
        if roomId == "" || MatrixServices.inst.eventCache[roomId] == nil {
            return 0
        }
        return (MatrixServices.inst.eventCache[roomId]?.count)!
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let event = MatrixServices.inst.eventCache[roomId]![row]
        
        switch event.type {
        case "m.room.message":
            if event.sender == MatrixServices.inst.client?.credentials.userId {
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutbound"), owner: self) as? RoomMessageEntry
                cell?.RoomMessageEntryOutboundFrom.stringValue = event.sender as String
                if event.content["formatted_body"] != nil {
                    // TODO: Make sure this is suitably sanitised
                    cell?.RoomMessageEntryOutboundText.attributedStringValue = (event.content["formatted_body"] as! String).toAttributedStringFromHTML(justify: .right)
                } else if event.content["body"] != nil {
                    cell?.RoomMessageEntryOutboundText.stringValue = event.content["body"] as! String
                }
                return cell
            } else {
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInbound"), owner: self) as? RoomMessageEntry
                cell?.RoomMessageEntryInboundFrom.stringValue = event.sender as String
                if event.content["formatted_body"] != nil {
                    // TODO: Make sure this is suitably sanitised
                    cell?.RoomMessageEntryInboundText.attributedStringValue = (event.content["formatted_body"] as! String).toAttributedStringFromHTML(justify: .left)
                } else if event.content["body"] != nil {
                    cell?.RoomMessageEntryInboundText.stringValue = event.content["body"] as! String
                }
                return cell
            }
        case "m.room.member":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as? RoomMessageEntry
            switch event.content["membership"] as! String {
            case "join":    cell?.RoomMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) joined the room"; break
            case "leave":   cell?.RoomMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) left the room"; break
            case "invite":  cell?.RoomMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) was invited to the room"; break
            case "ban":     cell?.RoomMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) was banned from the room"; break
            default:        cell?.RoomMessageEntryInlineText.stringValue = "\(event.stateKey.utf8) unknown event: \(event.stateKey)"; break
            }
            return cell
        case "m.room.name":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as? RoomMessageEntry
            cell?.RoomMessageEntryInlineText.stringValue = "Room renamed to \(event.content["name"] as! String)"
            return cell
        case "m.room.topic":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as? RoomMessageEntry
            cell?.RoomMessageEntryInlineText.stringValue = "Topic changed to \(event.content["topic"] as! String)"
            return cell
        default:
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as? RoomMessageEntry
            cell?.RoomMessageEntryInlineText.stringValue = "Unknown event \(event.type)"
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if row == MatrixServices.inst.eventCache[roomId]!.count-1 {
            RoomMessageTableView.scrollRowToVisible(row: row, animated: true)
        }
    }
    
    func uiDidSelectRoom(entry: RoomListEntry) {
        if entry.roomsCacheEntry?.roomId == nil {
            return
        }

        RoomName.isEnabled = true
        RoomInfoButton.isEnabled = true
        RoomPartButton.isEnabled = true
        RoomInsertButton.isEnabled = true
        RoomMessageInput.isEnabled = true

        RoomName.stringValue = entry.RoomListEntryName.stringValue
        RoomTopic.stringValue = entry.RoomListEntryTopic.stringValue.components(separatedBy: "\n")[1]
        
        roomId = (entry.roomsCacheEntry?.roomId)!

        RoomMessageTableView.reloadData()
    }
    
    func matrixDidRoomMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState) {
        if event.roomId == nil {
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
                if event.roomId == roomId {
                    RoomMessageTableView.insertRows(at: IndexSet.init(integer: (MatrixServices.inst.eventCache[event.roomId]?.count)! - 1), withAnimation: [ .slideUp, .effectFade ])
                    RoomMessageTableView.scrollToEndOfDocument(self)
                }
                break
            default:
                if event.roomId == roomId {
                    RoomMessageTableView.insertRows(at: IndexSet.init(integer: 0), withAnimation: [ .slideDown, .effectFade ])
                }
                break
            }
            return
        default:
            break
        }
        RoomMessageTableView.noteNumberOfRowsChanged()
    }
    func matrixDidRoomUserJoin() {}
    func martixDidRoomUserPart() {}
    
}
