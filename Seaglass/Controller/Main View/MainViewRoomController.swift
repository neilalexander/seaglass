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
    @IBOutlet var RoomInviteLabel: NSTextField!
    @IBOutlet var RoomInviteAcceptButton: NSButton!
    @IBOutlet var RoomInviteDeclineButton: NSButton!
    
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
        if unformattedText == "" {
            sender.stringValue = ""
            sender.isEnabled = true
            sender.becomeFirstResponder()
            return
        }
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
        
        roomTyping = false
        
        var returnedEvent: MXEvent?
        if sender.stringValue.starts(with: "/me ") {
            let startIndex = unformattedText.index(unformattedText.startIndex, offsetBy: 4)
            var localReturnedEvent: String? = nil
            MatrixServices.inst.session.room(withRoomId: roomId).sendEmote(String(unformattedText[startIndex...]), localEcho: &returnedEvent) { (response) in
                if case .success( _) = response {
                    if let index = MatrixServices.inst.eventCache[self.roomId]?.index(where: { $0.eventId == localReturnedEvent }) {
                        MatrixServices.inst.eventCache[self.roomId]?[index] = returnedEvent!
                    }
                }
                self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: localReturnedEvent)
            }
            MatrixServices.inst.eventCache[roomId]?.append(returnedEvent!)
            localReturnedEvent = returnedEvent?.eventId ?? nil
            matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: roomId).state, replaces: nil)
        } else {
            var localReturnedEvent: String? = nil
            MatrixServices.inst.session.room(withRoomId: roomId).sendTextMessage(unformattedText, formattedText: formattedText, localEcho: &returnedEvent) { (response) in
                if case .success( _) = response {
                    if let index = MatrixServices.inst.eventCache[self.roomId]?.index(where: { $0.eventId == localReturnedEvent }) {
                        MatrixServices.inst.eventCache[self.roomId]?[index] = returnedEvent!
                    }
                }
                self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: localReturnedEvent)
            }
            MatrixServices.inst.eventCache[roomId]?.append(returnedEvent!)
            localReturnedEvent = returnedEvent?.eventId ?? nil
            matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: roomId).state, replaces: nil)
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
            case "SegueToPartRoom":
                if let dest = segue.destinationController as? MainViewPartController {
                    dest.roomId = roomId
                }
                break
            default:
                return
            }
        }
    }
    
    func getFilteredRoomCache(for roomId: String) -> [MXEvent] {
        return MatrixServices.inst.eventCache[roomId]?.filter {
            !$0.isRedactedEvent() && $0.content.count > 0
        } ?? []
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if !MatrixServices.inst.eventCache.keys.contains(roomId) {
            return 0
        }
        if roomId == "" || MatrixServices.inst.eventCache[roomId] == nil {
            return 0
        }
        return getFilteredRoomCache(for: roomId).count
    }
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        let event = getFilteredRoomCache(for: roomId)[row]
        MatrixServices.inst.session.room(withRoomId: roomId).acknowledgeEvent(event, andUpdateReadMarker: true)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let event = getFilteredRoomCache(for: roomId)[row]
        var cell: RoomMessage
        
        if event.decryptionError != nil {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageInline
            cell.event = event
            return cell
        }
        
        switch event.type {
        case "m.room.message":
            var isCoalesced = false
            if row >= 1 {
                let previousEvent = getFilteredRoomCache(for: roomId)[row-1]
                isCoalesced = (
                    event.sender == previousEvent.sender &&
                    event.type == previousEvent.type &&
                    previousEvent.originServerTs.distance(to: event.originServerTs) <= 300000
                )
            }
            
            let messageSendErrorHandler = { (roomId, eventId, userId) in
                let sheet = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("MessageSendFailedSheet")) as! MainViewSendErrorController
                sheet.roomId = roomId!
                sheet.eventId = eventId!
                self.presentViewControllerAsSheet(sheet)
            } as (_: String?, _: String?, _: String?) -> ()
            
            if event.sender == MatrixServices.inst.client?.credentials.userId {
               // if event.isMediaAttachment() {
               //     cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutboundMedia"), owner: self) as! RoomMessage
               // } else {
                    if isCoalesced {
                        cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutboundCoalesced"), owner: self) as! RoomMessageOutgoingCoalesced
                        (cell as! RoomMessageOutgoingCoalesced).Icon.handler = messageSendErrorHandler
                    } else {
                        cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutbound"), owner: self) as! RoomMessageOutgoing
                        (cell as! RoomMessageOutgoing).Icon.handler = messageSendErrorHandler
                    }
               // }
            } else {
                if isCoalesced {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInboundCoalesced"), owner: self) as! RoomMessageIncomingCoalesced
                } else {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInbound"), owner: self) as! RoomMessageIncoming
                }
            }
            break
        default:
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageInline
            cell.event = event
        }

        cell.event = event
        cell.identifier = nil
        return cell
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        guard let scrollview = tableView.enclosingScrollView else { return }
        let y1 = scrollview.documentView!.intrinsicContentSize.height - RoomMessageTableView.enclosingScrollView!.contentSize.height
        let y2 = scrollview.documentVisibleRect.origin.y
        if abs(y1 - y2) < 64 {
            OperationQueue.main.addOperation({ self.RoomMessageTableView.scrollRowToVisible(row: self.getFilteredRoomCache(for: self.roomId).count-1, animated: true) })
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 1
    }
    
    func uiDidSelectRoom(entry: RoomListEntry) {
        guard let cacheEntry = entry.roomsCacheEntry else { return }
        
        if cacheEntry.roomId == roomId {
            return
        } 
        
        roomTyping = false
        
        let isInvite = cacheEntry.isInvite()
        RoomName.isEnabled = !isInvite
        RoomInfoButton.isEnabled = true
        RoomPartButton.isEnabled = !isInvite
        RoomEncryptionButton.isEnabled = !isInvite
 
        RoomInsertButton.alphaValue = isInvite ? 0 : 1
        RoomMessageInput.alphaValue = isInvite ? 0 : 1
        
        RoomInviteLabel.isHidden = !isInvite
        RoomInviteLabel.alphaValue = isInvite ? 1 : 0
        RoomInviteAcceptButton.isHidden = !isInvite
        RoomInviteAcceptButton.alphaValue = isInvite ? 1 : 0
        RoomInviteDeclineButton.isHidden = !isInvite
        RoomInviteDeclineButton.alphaValue = isInvite ? 1 : 0
        
        RoomInsertButton.isEnabled = !isInvite
        RoomMessageInput.isEnabled = !isInvite

        RoomName.stringValue = cacheEntry.roomDisplayName
        RoomTopic.stringValue = cacheEntry.roomTopic
        
        roomId = cacheEntry.roomId
 
        RoomMessageTableView.beginUpdates()
        RoomMessageTableView.reloadData()
        RoomMessageTableView.endUpdates()
        
        if cacheEntry.encrypted() {
            RoomMessageInput.placeholderString = "Encrypted message"
            RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockLockedTemplate)
        } else {
            RoomMessageInput.placeholderString = "Message"
            RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockUnlockedTemplate)
        }
        
        OperationQueue.main.addOperation({ self.RoomMessageTableView.scrollRowToVisible(row: self.getFilteredRoomCache(for: self.roomId).count-1, animated: true) })
    }
    
    func matrixDidRoomMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState, replaces: String?, removeOnReplace: Bool = false) {
        if event.roomId == nil {
            return
        }
        if !MatrixServices.inst.eventCache[event.roomId]!.contains(where: { $0.eventId == event.eventId }) {
            return
        }
        let cache = getFilteredRoomCache(for: roomId)
        if replaces != nil {
            if let index = cache.index(where: { $0.eventId == event.eventId }) {
                if !event.isRedactedEvent() && event.content.count > 0 {
                    OperationQueue.main.addOperation({ self.RoomMessageTableView.removeRows(at: IndexSet([index]), withAnimation: .effectGap) })
                    OperationQueue.main.addOperation({ self.RoomMessageTableView.insertRows(at: IndexSet([index]), withAnimation: .effectFade) })
                } else if removeOnReplace {
                    OperationQueue.main.addOperation({ self.RoomMessageTableView.removeRows(at: IndexSet([index]), withAnimation: .slideUp) })
                }
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
            if event.roomId == roomId, let roomName = event.content["name"] as? String {
                RoomName.stringValue = roomName
            }
            break
        case "m.room.topic":
            if event.roomId == roomId, let roomTopic = event.content["topic"] as? String {
                RoomTopic.stringValue = roomTopic
            }
            break
        default:
            return
        }
        if event.roomId == roomId {
            RoomMessageTableView.beginUpdates()
            RoomMessageTableView.noteNumberOfRowsChanged()
            RoomMessageTableView.endUpdates()
        }
    }
    func matrixDidRoomUserJoin() {}
    func matrixDidRoomUserPart() {}
    
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return [] }
        if MatrixServices.inst.session.invitedRooms().contains(where: { $0.roomId == room.roomId }) {
            return []
        }
        var actions: [NSTableViewRowAction] = []
        if edge == .trailing {
            if room.state.powerLevels.redact <= room.state.powerLevels.powerLevelOfUser(withUserID: MatrixServices.inst.session.myUser.userId) {
                actions.append(NSTableViewRowAction(style: .destructive, title: "Redact", handler: { (action, row) in
                    let event = self.getFilteredRoomCache(for: room.roomId)[row]
                    tableView.removeRows(at: IndexSet(integer: row), withAnimation: [.slideDown, .effectFade])
                    room.redactEvent(event.eventId, reason: nil, completion: { (response) in
                        if response.isFailure, let error = response.error {
                            tableView.insertRows(at: IndexSet(integer: row), withAnimation: [.slideDown, .effectFade])
                            let alert = NSAlert()
                            alert.messageText = "Failed to redact message"
                            alert.informativeText = error.localizedDescription
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    })
                }))
            }
        } else {
            
        }
        return actions
    }
    
    @IBAction func acceptInviteButtonClicked(_ sender: NSButton) {
        if !MatrixServices.inst.session.invitedRooms().contains(where: { $0.roomId == roomId }) {
            return
        }
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return }
        RoomInviteAcceptButton.isEnabled = false
        RoomInviteDeclineButton.isEnabled = false
        MatrixServices.inst.session.stopPeeking(MXPeekingRoom(roomId: room.roomId, andMatrixSession: MatrixServices.inst.session))
        MatrixServices.inst.session.joinRoom(roomId) { (response) in
            if response.isFailure, let error = response.error {
                let alert = NSAlert()
                alert.messageText = "Failed to accept invite for \(self.roomId)"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                self.RoomInviteAcceptButton.isEnabled = true
                self.RoomInviteDeclineButton.isEnabled = true
            } else {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 1
                    self.RoomInviteLabel.animator().alphaValue = 0
                    self.RoomInviteAcceptButton.animator().alphaValue = 0
                    self.RoomInviteDeclineButton.animator().alphaValue = 0
                    self.RoomMessageInput.animator().alphaValue = 1
                    self.RoomInsertButton.animator().alphaValue = 1
                }, completionHandler: {
                    self.RoomMessageInput.isEnabled = true
                    self.RoomInsertButton.isEnabled = true
                    self.RoomInviteLabel.animator().isHidden = true
                    self.RoomInviteAcceptButton.animator().isHidden = true
                    self.RoomInviteDeclineButton.animator().isHidden = true
                })
            }
        }
    }
    
    @IBAction func declineInviteButtonClicked(_ sender: NSButton) {
        if !MatrixServices.inst.session.invitedRooms().contains(where: { $0.roomId == roomId }) {
            return
        }
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return }
        RoomInviteAcceptButton.isEnabled = false
        RoomInviteDeclineButton.isEnabled = false
        MatrixServices.inst.session.stopPeeking(MXPeekingRoom(roomId: room.roomId, andMatrixSession: MatrixServices.inst.session))
        mainController?.roomsDelegate?.matrixDidPartRoom(room)
        MatrixServices.inst.session.leaveRoom(roomId) { (response) in
            if response.isFailure, let error = response.error {
                let alert = NSAlert()
                alert.messageText = "Failed to decline invite for \(self.roomId)"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                self.mainController?.roomsDelegate?.matrixDidJoinRoom(room)
            }
        }
    }
    
    @IBAction func emojiButtonClicked(_ sender: NSButton) {
        RoomMessageInput.becomeFirstResponder()
        NSApp.orderFrontCharacterPalette(nil)
    }
}
