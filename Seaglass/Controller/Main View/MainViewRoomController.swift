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

class MainViewRoomController: NSViewController, MatrixRoomDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet var RoomName: NSTokenField!
    @IBOutlet var RoomTopic: NSTextField!
    @IBOutlet var RoomMessageInput: MessageInputField!
    @IBOutlet var RoomMessageScrollView: NSScrollView!
    @IBOutlet var RoomMessageClipView: NSClipView!
    @IBOutlet var RoomMessageTableView: MainViewTableView!
    @IBOutlet var RoomMessageTableColumn: NSTableColumn!
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
    var roomIsPaginating: Bool = false
    var roomIsOverscrolling: Bool = false
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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        RoomMessageInput.textField.action = #selector(messageEntryFieldSubmit)
        RoomMessageInput.textField.target = self
        RoomMessageInput.delegate = self
        
        RoomMessageScrollView.postsBoundsChangedNotifications = true
        RoomMessageScrollView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(scrollViewDidScroll), name: NSScrollView.didLiveScrollNotification, object: RoomMessageScrollView)
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
        if sender.stringValue.starts(with: "/invite ") {
            let startIndex = unformattedText.index(unformattedText.startIndex, offsetBy: 8)
            let invitee = MXRoomInvitee.userId(String(unformattedText[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines))
            
            MatrixServices.inst.session.room(withRoomId: roomId).invite(invitee) { (response) in
                if response.isFailure {
                    let alert = NSAlert()
                    alert.messageText = "Failed to invite user"
                    alert.informativeText = response.error!.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        } else if sender.stringValue.starts(with: "/me ") {
            let startIndex = unformattedText.index(unformattedText.startIndex, offsetBy: 4)
            var localReturnedEvent: String? = nil
            MatrixServices.inst.session.room(withRoomId: roomId).sendEmote(String(unformattedText[startIndex...]), localEcho: &returnedEvent) { (response) in
                if case .success( _) = response {
                    if let index = MatrixServices.inst.roomCaches[self.roomId]!.unfilteredContent.index(where: { $0.eventId == localReturnedEvent }) {
                        MatrixServices.inst.roomCaches[self.roomId]!.replace(returnedEvent!, at: index)
                    }
                }
                self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: localReturnedEvent)
            }
            MatrixServices.inst.roomCaches[roomId]!.unfilteredContent.append(returnedEvent!)
            localReturnedEvent = returnedEvent?.eventId ?? nil
            matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: roomId).state, replaces: nil)
        } else {
            var localReturnedEvent: String? = nil
            MatrixServices.inst.session.room(withRoomId: roomId).sendTextMessage(unformattedText, formattedText: formattedText, localEcho: &returnedEvent) { (response) in
                if case .success( _) = response {
                    if let index = MatrixServices.inst.roomCaches[self.roomId]!.unfilteredContent.index(where: { $0.eventId == localReturnedEvent }) {
                        MatrixServices.inst.roomCaches[self.roomId]!.replace(returnedEvent!, at: index)
                    }
                }
                self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state, replaces: localReturnedEvent)
            }
            MatrixServices.inst.roomCaches[roomId]!.unfilteredContent.append(returnedEvent!)
            localReturnedEvent = returnedEvent?.eventId ?? nil
            matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: roomId).state, replaces: nil)
        }
        sender.stringValue = ""
        sender.isEnabled = true
        sender.becomeFirstResponder()
    }
    
    public override func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField == RoomMessageInput.textField {
            roomTyping = !RoomMessageInput.textField.stringValue.isEmpty
        }
    }
    
    @objc func scrollViewDidScroll(_ notification: NSNotification) {
        let overscrollHeight = RoomMessageTableView.frame.height + RoomMessageClipView.contentInsets.top + RoomMessageClipView.contentInsets.bottom
        if RoomMessageClipView.bounds.minY >= 0  &&
           RoomMessageClipView.bounds.maxY <= overscrollHeight {
            roomIsOverscrolling = false
            return
        }
        if roomIsPaginating || roomIsOverscrolling {
            return
        }
        roomIsOverscrolling = true
        if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
            let direction: MXTimelineDirection = RoomMessageClipView.bounds.minY < 0 ? .backwards : .forwards
            if room.liveTimeline.canPaginate(direction) {
                roomIsPaginating = true
                let eventCacheCountBeforePagination = MatrixServices.inst.roomCaches[roomId]!.filteredContent.count
                room.liveTimeline.paginate(15, direction: direction, onlyFromStore: false) { (response) in
                    if response.isFailure {
                        print("Failed to paginate: \(response.error!.localizedDescription)")
                        return
                    }
                    let numberPaginatedEvents = min(15, MatrixServices.inst.roomCaches[self.roomId]!.filteredContent.count - eventCacheCountBeforePagination)
                    if numberPaginatedEvents > 0 {
                        self.RoomMessageTableView.insertRows(at: IndexSet(0..<numberPaginatedEvents), withAnimation: NSTableView.AnimationOptions.slideUp)
                        self.RoomMessageTableView.noteNumberOfRowsChanged()
                        self.roomIsPaginating = false
                    }
                }
            }
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier != nil {
            switch segue.identifier!.rawValue {
            case "SegueToRoomSettings":
                if let dest = segue.destinationController as? RoomSettingsController {
                    dest.roomId = roomId
                }
                break
            case "SegueToRoomEncryption":
                if let dest = segue.destinationController as? MainViewEncryptionController {
                    dest.roomId = roomId
                }
                break
            case "SegueToPartRoom":
                if let dest = segue.destinationController as? MainViewPartController {
                    dest.roomId = roomId
                }
                break
            case "SegueToRoomInvite":
                if let dest = segue.destinationController as? MainViewInviteController {
                    dest.roomId = roomId
                }
                break
            default:
                return
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if MatrixServices.inst.roomCaches.keys.contains(roomId) {
            return MatrixServices.inst.roomCaches[roomId]!.filteredContent.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard roomId != "" && MatrixServices.inst.roomCaches.keys.contains(roomId) else {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageInline
            cell.Text.stringValue = "Room ID not known - this shouldn't happen"
            return cell
        }
        
        guard MatrixServices.inst.roomCaches[roomId]!.filteredContent.count > row else {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageInline
            cell.Text.stringValue = "Invalid row \(row) - this shouldn't happen"
            return cell
        }
        
        let event = MatrixServices.inst.roomCaches[roomId]!.filteredContent[row]
        var cell: RoomMessage
        
        if event.decryptionError != nil {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageInline
            cell.event = event
            return cell
        }
        
        switch event.type {
        case "m.sticker":
            fallthrough
        case "m.room.message":
            var isCoalesced = false
            if row >= 1 {
                let previousEvent = MatrixServices.inst.roomCaches[roomId]!.filteredContent[row-1]
                isCoalesced = (
                    event.sender == previousEvent.sender &&
                    event.type == previousEvent.type &&
                    previousEvent.originServerTs.distance(to: event.originServerTs) <= 300000
                )
            }
            
            let messageIconHandler = { (sender, room, event, userId) in
                guard room != nil && event != nil else { return }
                if event!.sentState == MXEventSentStateFailed {
                    let sheet = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("MessageSendFailedSheet")) as! MainViewSendErrorController
                    sheet.roomId = room!.roomId
                    sheet.eventId = event!.eventId
                    self.presentViewControllerAsSheet(sheet)
                } else if event!.isEncrypted {
                    let sheet = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("EncryptionDeviceInfo")) as! PopoverEncryptionDevice
                    sheet.event = event
                    self.presentViewController(sheet, asPopoverRelativeTo: sheet.view.frame, of: sender, preferredEdge: .maxX, behavior: .transient)
                }
            } as (_: NSView, _: MXRoom?, _: MXEvent?, _: String?) -> ()
            
            if event.sender == MatrixServices.inst.client?.credentials.userId {
                if isCoalesced {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutboundCoalesced"), owner: self) as! RoomMessageOutgoingCoalesced
                    (cell as! RoomMessageOutgoingCoalesced).Icon.handler = messageIconHandler
                } else {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryOutbound"), owner: self) as! RoomMessageOutgoing
                    (cell as! RoomMessageOutgoing).Icon.handler = messageIconHandler
                }
            } else {
                if isCoalesced {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInboundCoalesced"), owner: self) as! RoomMessageIncomingCoalesced
                    (cell as! RoomMessageIncomingCoalesced).Icon.handler = messageIconHandler
                } else {
                    cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInbound"), owner: self) as! RoomMessageIncoming
                    (cell as! RoomMessageIncoming).Icon.handler = messageIconHandler
                }
            }
            break
        default:
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RoomMessageEntryInline"), owner: self) as! RoomMessageInline
            cell.event = event
        }

        cell.event = event
        return cell
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        guard let scrollview = tableView.enclosingScrollView else { return }
        let y1 = scrollview.documentView!.intrinsicContentSize.height - RoomMessageTableView.enclosingScrollView!.contentSize.height
        let y2 = scrollview.documentVisibleRect.origin.y
        if abs(y1 - y2) < 64 {
            OperationQueue.main.addOperation({ self.RoomMessageTableView.scrollRowToVisible(row: MatrixServices.inst.roomCaches[self.roomId]!.filteredContent.count-1, animated: true) })
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 1
    }
    
    func uiRoomNeedsCryptoReload() {
        for view in RoomMessageTableView.subviews {
            for cell in view.subviews {
                if let message = cell as? RoomMessage {
                    message.updateIcon()
                }
            }
        }
    }
    
    func uiRoomStartInvite() {
        if let board = self.storyboard {
            let identifier = NSStoryboard.SceneIdentifier("RoomInviteController")
            let inviteController = board.instantiateController(withIdentifier: identifier) as! MainViewInviteController
            inviteController.roomId = roomId
            self.presentViewControllerAsSheet(inviteController)
        }
    }
    
    func uiDidSelectRoom(entry: RoomListEntry) {
        guard let cacheEntry = entry.roomsCacheEntry else { return }
        
        if cacheEntry.roomId == roomId {
            return
        }
    
        roomTyping = false
        roomIsPaginating = false
        roomIsOverscrolling = false
        
        let isInvite = cacheEntry.isInvite()
        RoomName.isEnabled = !isInvite
        RoomInfoButton.isEnabled = true
        RoomPartButton.isEnabled = !isInvite
        RoomEncryptionButton.isEnabled = !isInvite
 
        RoomInsertButton.alphaValue = isInvite ? 0 : 1
        RoomMessageInput.alphaValue = isInvite ? 0 : 1
        RoomMessageInput.emojiButton.isEnabled = !isInvite
        
        RoomInviteLabel.isHidden = !isInvite
        RoomInviteLabel.alphaValue = isInvite ? 1 : 0
        RoomInviteAcceptButton.isHidden = !isInvite
        RoomInviteAcceptButton.alphaValue = isInvite ? 1 : 0
        RoomInviteDeclineButton.isHidden = !isInvite
        RoomInviteDeclineButton.alphaValue = isInvite ? 1 : 0
        
        RoomInsertButton.isEnabled = !isInvite
        RoomMessageInput.textField.isEnabled = !isInvite

        RoomName.stringValue = cacheEntry.roomDisplayName
        RoomTopic.stringValue = cacheEntry.roomTopic
        
        roomId = cacheEntry.roomId
        
        RoomMessageTableView.unbind(NSBindingName.content)
        RoomMessageTableColumn.unbind(NSBindingName.value)
        if MatrixServices.inst.roomCaches.keys.contains(roomId) {
            RoomMessageTableView.bind(NSBindingName.content, to: MatrixServices.inst.roomCaches[roomId]!, withKeyPath: "filteredContent", options: nil)
            RoomMessageTableColumn.bind(NSBindingName.value, to: MatrixServices.inst.roomCaches[roomId]!, withKeyPath: "filteredContent", options: nil)
        }
 
        if cacheEntry.encrypted() {
            RoomMessageInput.textField.placeholderString = "Encrypted message"
            RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockLockedTemplate)
        } else {
            RoomMessageInput.textField.placeholderString = "Message"
            RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockUnlockedTemplate)
        }
        
        let roomDidPaginate = {
          /*  self.RoomMessageTableView.beginUpdates()
            self.RoomMessageTableView.reloadData()
            self.RoomMessageTableView.endUpdates()
            OperationQueue.main.addOperation({
                self.RoomMessageTableView.scrollRowToVisible(row: self.roomCache.filteredContent.count-1, animated: true)
                self.RoomMessageInput.window?.makeFirstResponder(self.RoomMessageInput.textField)
            })  */
        }
        
        if let room = MatrixServices.inst.session.room(withRoomId: cacheEntry.roomId) {
            room.liveTimeline.resetPagination()
            if MatrixServices.inst.roomCaches[roomId]!.filteredContent.count < 50 {
                room.liveTimeline.paginate(50, direction: .backwards, onlyFromStore: false) { _ in
                    roomDidPaginate()
                }
            }
        }
    }
    
    func matrixDidRoomMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState, replaces: String?, removeOnReplace: Bool = false) {
        guard event.roomId == roomId else { return }
        guard MatrixServices.inst.roomCaches[roomId]!.unfilteredContent.contains(where: { $0.eventId == event.eventId }) else { return }
        
        switch event.type {
        case "m.typing":
            return
        case "m.receipt":
            return
        case "m.room.message":
            break
        case "m.room.member":
            break
        case "m.room.encryption":
            if event.roomId == roomId {
                if roomState.isEncrypted {
                    RoomMessageInput.textField.placeholderString = "Encrypted message"
                    RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockLockedTemplate)
                } else {
                    RoomMessageInput.textField.placeholderString = "Message"
                    RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockUnlockedTemplate)
                }
                self.uiRoomNeedsCryptoReload()
            }
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
                    let event = MatrixServices.inst.roomCaches[self.roomId]!.filteredContent[row]
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
                    self.RoomMessageInput.textField.isEnabled = true
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
}
