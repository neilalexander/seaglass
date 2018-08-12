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
import Down

class MainViewRoomController: NSViewController, MatrixRoomDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
    @IBOutlet var RoomName: NSTokenField!
    @IBOutlet var RoomTopic: NSTextField!
    @IBOutlet var RoomMessageInput: NSTextField!
    @IBOutlet var RoomMessageScrollView: NSScrollView!
    @IBOutlet var RoomMessageClipView: NSClipView!
    @IBOutlet var RoomMessageTableView: MainViewTableView!
    @IBOutlet var RoomInfoButton: NSButton!
    @IBOutlet var RoomPartButton: NSButton!
    @IBOutlet var RoomInsertButton: NSButton!
    @IBOutlet var RoomEncryptionButton: NSButton!
    
    weak public var mainController: MainViewController?
    
    var roomId: String = ""
    var roomIsTyping: Bool = false
    var roomTyping: Bool {
        set {
            if (newValue && !roomIsTyping) || (!newValue && roomIsTyping) {
                roomIsTyping = newValue
                if roomId != "" {
                    MatrixServices.inst.session.room(withRoomId: roomId).sendTypingNotification(typing: roomIsTyping, timeout: 30) { (response) in
                        if response.isFailure {
                            print("Failed to send typing notification for room \(self.roomId)")
                        }
                    }
                }
            }
        }
        get {
            return roomIsTyping
        }
    }

    @IBAction func messageEntryFieldSubmit(_ sender: NSTextField) {
        if roomId == "" {
            return
        }
        
        sender.isEnabled = false
        
        var formattedText: String
        let unformattedText = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let options = DownOptions(rawValue: 1 << 3)
        do {
            // TODO: Make sure this is suitably sanitised
            formattedText = try Down(markdownString: unformattedText).toHTML(options)
            formattedText = formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if formattedText.hasPrefix("<p>") {
                formattedText = String(formattedText.dropFirst(3))
            }
            if formattedText.hasSuffix("</p>") {
                formattedText = String(formattedText.dropLast(4))
            }
        } catch {
            formattedText = unformattedText
        }
        
        self.roomTyping = false
        
        var returnedEvent: MXEvent?
        if sender.stringValue.starts(with: "/me ") {
            let startIndex = unformattedText.index(unformattedText.startIndex, offsetBy: 4)
            var localReturnedEvent: String? = nil
            MatrixServices.inst.session.room(withRoomId: roomId).sendEmote(String(unformattedText[startIndex...]), localEcho: &returnedEvent) { (response) in
                if case .success( _) = response {
                    MatrixServices.inst.eventCache[self.roomId]?.append(returnedEvent!)
                    self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: localReturnedEvent)
                }
            }
            localReturnedEvent = returnedEvent?.eventId ?? nil
            self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: nil)
        } else {
            var localReturnedEvent: String? = nil
            MatrixServices.inst.session.room(withRoomId: roomId).sendTextMessage(unformattedText, formattedText: formattedText, localEcho: &returnedEvent) { (response) in
                if case .success( _) = response {
                    MatrixServices.inst.eventCache[self.roomId]?.append(returnedEvent!)
                    self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: localReturnedEvent)
                }
            }
            localReturnedEvent = returnedEvent?.eventId ?? nil
            self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: nil)
        }
        sender.stringValue = ""
        sender.isEnabled = true
        sender.becomeFirstResponder()
    }
    
    public override func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField == RoomMessageInput {
            roomTyping = !RoomMessageInput.stringValue.isEmpty
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier != nil {
            switch segue.identifier!.rawValue {
            case "SegueToRoomSettings":
                if let dest = segue.destinationController as? RoomSettingsController {
                    dest.roomId = roomId
                }
                break
            default:
                return
            }
        }
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
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        let event = MatrixServices.inst.eventCache[roomId]![row]
        MatrixServices.inst.session.room(withRoomId: roomId).acknowledgeEvent(event, andUpdateReadMarker: true)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let event = MatrixServices.inst.eventCache[roomId]![row]
        let room = MatrixServices.inst.session.room(withRoomId: roomId)!
        
        let padlockWidth: CGFloat = 16
        let padlockHeight: CGFloat = 12
        let padlockColor: NSColor = event.isEncrypted ?
            NSColor(deviceRed: 0.38, green: 0.65, blue: 0.53, alpha: 0.75) :
            NSColor(deviceRed: 0.79, green: 0.31, blue: 0.27, alpha: 0.75)
        let padlockImage: NSImage = event.isEncrypted ?
            NSImage(named: NSImage.Name.lockLockedTemplate)!.tint(with: padlockColor) :
            NSImage(named: NSImage.Name.lockUnlockedTemplate)!.tint(with: padlockColor)
        
        var cell: RoomMessageEntry
        
        switch event.type {
        case "m.room.message":
            var cellAttributedStringValue: NSAttributedString = NSAttributedString()
            var cellStringValue: String = ""
            
           // if event.content["formatted_body"] != nil {
           //     let justification = event.sender == MatrixServices.inst.client?.credentials.userId ? NSTextAlignment.right : NSTextAlignment.left
           //     cellAttributedStringValue = (event.content["formatted_body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).toAttributedStringFromHTML(justify: justification)
           //     cellStringValue = (event.content["formatted_body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
           // } else if event.content["body"] != nil {
           //     cellStringValue = (event.content["body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
           // }
            
            if event.content["body"] != nil {
                let justification = event.sender == MatrixServices.inst.client?.credentials.userId ? NSTextAlignment.right : NSTextAlignment.left
                cellAttributedStringValue = (event.content["body"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).toAttributedStringFromMarkdown(justify: justification)
            }
            
            var isCoalesced = false
            if row >= 1 {
                let previousEvent = MatrixServices.inst.eventCache[roomId]![row-1]
                isCoalesced = (
                    event.sender == previousEvent.sender &&
                    event.type == previousEvent.type &&
                    previousEvent.originServerTs.distance(to: event.originServerTs) <= 300000
                )
            }
            
            if event.sender == MatrixServices.inst.client?.credentials.userId {
                if isCoalesced {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutboundCoalesced"), owner: self) as! RoomMessageEntry
                    if cellAttributedStringValue.length > 0 {
                        cell.RoomMessageEntryOutboundCoalescedText.attributedStringValue = cellAttributedStringValue
                    } else if cellStringValue != "" {
                        cell.RoomMessageEntryOutboundCoalescedText.stringValue = cellStringValue
                    }
                    cell.RoomMessageEntryOutboundCoalescedPadlock.isHidden = !room.state.isEncrypted
                    cell.RoomMessageEntryOutboundCoalescedPadlock.image = padlockImage
                    cell.RoomMessageEntryOutboundCoalescedPadlock.setFrameSize(room.state.isEncrypted ? NSMakeSize(padlockWidth, padlockHeight) : NSMakeSize(0, padlockHeight))
                    cell.RoomMessageEntryOutboundCoalescedTextConstraint.constant -= padlockWidth - cell.RoomMessageEntryOutboundCoalescedPadlock.frame.size.width
                    break
                } else {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutbound"), owner: self) as! RoomMessageEntry
                    cell.RoomMessageEntryOutboundFrom.stringValue = MatrixServices.inst.session.room(withRoomId: roomId).state.memberName(event.sender) ?? event.sender as String
                    cell.RoomMessageEntryOutboundIcon.setAvatar(forUserId: event.sender)
                    if cellAttributedStringValue.length > 0 {
                        cell.RoomMessageEntryOutboundText.attributedStringValue = cellAttributedStringValue
                    } else if cellStringValue != "" {
                        cell.RoomMessageEntryOutboundText.stringValue = cellStringValue
                    }
                    cell.RoomMessageEntryOutboundPadlock.isHidden = !room.state.isEncrypted
                    cell.RoomMessageEntryOutboundPadlock.image = padlockImage
                    cell.RoomMessageEntryOutboundPadlock.setFrameSize(room.state.isEncrypted ? NSMakeSize(padlockWidth, padlockHeight) : NSMakeSize(0, padlockHeight))
                    cell.RoomMessageEntryOutboundTextConstraint.constant -= padlockWidth - cell.RoomMessageEntryOutboundPadlock.frame.size.width
                    if event.sentState == MXEventSentStateSending {
                        cell.alphaValue = 0.4
                    }
                    break
                }
            } else {
                if isCoalesced {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInboundCoalesced"), owner: self) as! RoomMessageEntry
                    if cellAttributedStringValue.length > 0 {
                        cell.RoomMessageEntryInboundCoalescedText.attributedStringValue = cellAttributedStringValue
                    } else if cellStringValue != "" {
                        cell.RoomMessageEntryInboundCoalescedText.stringValue = cellStringValue
                    }
                    cell.RoomMessageEntryInboundCoalescedPadlock.isHidden = !room.state.isEncrypted
                    cell.RoomMessageEntryInboundCoalescedPadlock.image = padlockImage
                    cell.RoomMessageEntryInboundCoalescedPadlock.setFrameSize(room.state.isEncrypted ? NSMakeSize(padlockWidth, padlockHeight) : NSMakeSize(0, padlockHeight))
                    cell.RoomMessageEntryInboundCoalescedTextConstraint.constant -= padlockWidth - cell.RoomMessageEntryInboundCoalescedPadlock.frame.size.width
                    break
                } else {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInbound"), owner: self) as! RoomMessageEntry
                    cell.RoomMessageEntryInboundFrom.stringValue = MatrixServices.inst.session.room(withRoomId: roomId).state.memberName(event.sender) ?? event.sender as String
                    cell.RoomMessageEntryInboundIcon.setAvatar(forUserId: event.sender)
                    if cellAttributedStringValue.length > 0 {
                        cell.RoomMessageEntryInboundText.attributedStringValue = cellAttributedStringValue
                    } else if cellStringValue != "" {
                        cell.RoomMessageEntryInboundText.stringValue = cellStringValue
                    }
                    cell.RoomMessageEntryInboundPadlock.isHidden = !room.state.isEncrypted
                    cell.RoomMessageEntryInboundPadlock.image = padlockImage
                    cell.RoomMessageEntryInboundPadlock.setFrameSize(room.state.isEncrypted ? NSMakeSize(padlockWidth, padlockHeight) : NSMakeSize(0, padlockHeight))
                    cell.RoomMessageEntryInboundTextConstraint.constant -= padlockWidth - cell.RoomMessageEntryInboundPadlock.frame.size.width
                    if event.sentState == MXEventSentStateSending {
                        cell.alphaValue = 0.4
                    }
                    break
                }
            }
        case "m.room.member":
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageEntry
            let displayName = MatrixServices.inst.session.room(withRoomId: roomId).state.memberName(event.stateKey) ?? event.stateKey as String
            switch event.content["membership"] as! String {
            case "join":    cell.RoomMessageEntryInlineText.stringValue = "\(displayName) joined the room"; break
            case "leave":   cell.RoomMessageEntryInlineText.stringValue = "\(displayName) left the room"; break
            case "invite":  cell.RoomMessageEntryInlineText.stringValue = "\(displayName) was invited to the room"; break
            case "ban":     cell.RoomMessageEntryInlineText.stringValue = "\(displayName) was banned from the room"; break
            default:        cell.RoomMessageEntryInlineText.stringValue = "\(displayName) unknown event: \(event.stateKey)"; break
            }
            return cell
        case "m.room.name":
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageEntry
            if event.content["name"] as! String != "" {
                cell.RoomMessageEntryInlineText.stringValue = "Room renamed: \(event.content["name"] as! String)"
            } else {
                cell.RoomMessageEntryInlineText.stringValue = "Room name removed"
            }
            return cell
        case "m.room.topic":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageEntry
            if event.content["topic"] as! String != "" {
                cell.RoomMessageEntryInlineText.stringValue = "Room topic changed: \(event.content["topic"] as! String)"
            } else {
                cell.RoomMessageEntryInlineText.stringValue = "Room topic removed"
            }
            return cell
        case "m.room.avatar":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageEntry
            if event.content["url"] as! String != "" {
                cell.RoomMessageEntryInlineText.stringValue = "Room avatar changed"
            } else {
                cell.RoomMessageEntryInlineText.stringValue = "Room avatar removed"
            }
            return cell
        case "m.room.canonical_alias":
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageEntry
            if event.content["alias"] as! String != "" {
                cell.RoomMessageEntryInlineText.stringValue = "Primary room alias set to \(event.content["alias"] as! String)"
            } else {
                cell.RoomMessageEntryInlineText.stringValue = "Primary room alias removed"
            }
            break
        case "m.room.create":
            let displayName = MatrixServices.inst.session.room(withRoomId: roomId).state.memberName(event.content["creator"] as! String) ?? event.content["creator"] as! String
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageEntry
            cell.RoomMessageEntryInlineText.stringValue = "Room created by \(displayName)"
            break
        default:
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageEntry
            cell.RoomMessageEntryInlineText.stringValue = "Unknown event \(event.type)"
            print(event)
            break
        }

        cell.identifier = nil
        return cell
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        let scrollview = tableView.enclosingScrollView!
        let y1 = scrollview.documentView!.intrinsicContentSize.height - RoomMessageTableView.enclosingScrollView!.contentSize.height
        let y2 = scrollview.documentVisibleRect.origin.y
        if abs(y1 - y2) < 32 {
            RoomMessageTableView.scroll(NSPoint(x: 0, y: y1 + rowView.intrinsicContentSize.height + (RoomMessageTableView.enclosingScrollView?.contentInsets.bottom)!))
        }
    }
    
    func uiDidSelectRoom(entry: RoomListEntry) {
        if entry.roomsCacheEntry?.roomId == nil {
            return
        }
        if entry.roomsCacheEntry?.roomId == roomId {
            return
        }
        
        roomTyping = false

        RoomName.isEnabled = true
        RoomInfoButton.isEnabled = true
        RoomPartButton.isEnabled = true
        RoomEncryptionButton.isEnabled = true
        RoomInsertButton.isEnabled = true
        RoomMessageInput.isEnabled = true

        RoomName.stringValue = entry.RoomListEntryName.stringValue
        RoomTopic.stringValue = entry.RoomListEntryTopic.stringValue.components(separatedBy: "\n")[1]
        
        roomId = (entry.roomsCacheEntry?.roomId)!

        RoomMessageTableView.beginUpdates()
        RoomMessageTableView.reloadData()
        RoomMessageTableView.endUpdates()
        
        if entry.roomsCacheEntry!.encrypted() {
            RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockLockedTemplate)
        } else {
            RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockUnlockedTemplate)
        }
        
        MatrixServices.inst.session.room(withRoomId: roomId).markAllAsRead()
    }
    
    func matrixDidRoomMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState, replaces: String?) {
        if event.roomId == nil {
            return
        }
        if !MatrixServices.inst.eventCache[event.roomId]!.contains(where: { $0.eventId == event.eventId }) {
            return
        }
        if replaces != nil {
            let index = MatrixServices.inst.eventCache[event.roomId]!.index(where: { $0.eventId == event.eventId })
            if index != nil {
                RoomMessageTableView.beginUpdates()
                RoomMessageTableView.reloadData(forRowIndexes: IndexSet.init(integer: index!), columnIndexes: IndexSet.init(integer: 0))
                RoomMessageTableView.noteNumberOfRowsChanged()
                RoomMessageTableView.endUpdates()
                return
            }
        }
        switch event.type {
        case "m.typing":
            return
        case "m.receipt":
            return
        case "m.room.message":
            break
        case "m.room.member":
            break
        case "m.room.name":
            if event.roomId == roomId {
                RoomName.stringValue = event.content["name"] as! String
            }
            break
        case "m.room.topic":
            if event.roomId == roomId {
                RoomTopic.stringValue = event.content["topic"] as! String
            }
            break
        default:
            return
        }
        RoomMessageTableView.beginUpdates()
        RoomMessageTableView.noteNumberOfRowsChanged()
        RoomMessageTableView.endUpdates()
    }
    func matrixDidRoomUserJoin() {}
    func matrixDidRoomUserPart() {}
}
