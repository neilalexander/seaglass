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
import WebKit

class MainViewRoomController: NSViewController, MatrixRoomDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    @IBOutlet var RoomName: NSTokenField!
    @IBOutlet var RoomTopic: NSTextField!
    @IBOutlet var RoomMessageView: WKWebView!
    @IBOutlet var RoomMessageInput: MessageInputField!
    @IBOutlet var RoomInfoButton: NSButton!
    @IBOutlet var RoomPartButton: NSButton!
    @IBOutlet var RoomInsertButton: NSButton!
    @IBOutlet var RoomEncryptionButton: NSButton!
    @IBOutlet var RoomInviteLabel: NSTextField!
    @IBOutlet var RoomInviteAcceptButton: NSButton!
    @IBOutlet var RoomInviteDeclineButton: NSButton!
    @IBOutlet var ConnectivityBar: NSBox!
    
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
                    if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
                        room.sendTypingNotification(typing: roomIsTyping, timeout: 30) { (response) in
                            if response.isFailure {
                                print("Failed to send typing notification for room \(self.roomId)")
                            }
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
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        //if message.name == "callbackSwift" {
            print("JavaScript is sending a message \(message.body)")
        //}
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard roomId != "" else { return }
        for event in MatrixServices.inst.roomCaches[roomId]!.filteredContent {
            do {
                let str = NSString(data: try JSONSerialization.data(
                    withJSONObject: event.isEncrypted ? event.clear.jsonDictionary() : event.jsonDictionary() ?? [:],
                    options: JSONSerialization.WritingOptions.prettyPrinted),
                                   encoding: String.Encoding.utf8.rawValue
                    )! as String
                let script = "drawEvents([\(str)], true);"
                RoomMessageView.evaluateJavaScript(script) { (result, error) in
                    if error != nil {
                        print("Javascript error occured in webView:didFinish: \(error!.localizedDescription)")
                        print("Script: \(script)")
                    }
                }
            } catch {
                print("Javascript exception occured in webView:didFinish: \(error.localizedDescription)")
                print("Script not available")
            }
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("An error from web view: \(message)")
        
        completionHandler()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let source = "document.addEventListener('message', function(e) { window.webkit.messageHandlers.callbackSwift.postMessage(e.data); })"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(script)
        userContentController.add(self, name: "callbackSwift")
        
        let htmlPath = Bundle.main.path(forResource: "RoomMessageView", ofType: "html")
        let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
        let htmlFolder = URL(fileURLWithPath: Bundle.main.resourcePath!, isDirectory: true)
        
        RoomMessageView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlFolder)
        RoomMessageView.navigationDelegate = self
        RoomMessageView.configuration.userContentController = userContentController
        //RoomMessageView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        RoomMessageView.allowsBackForwardNavigationGestures = false
        RoomMessageView.allowsLinkPreview = false
        RoomMessageView.allowsMagnification = false
        RoomMessageView.uiDelegate = self
        
        RoomMessageInput.textField.action = #selector(messageEntryFieldSubmit)
        RoomMessageInput.textField.target = self
        RoomMessageInput.delegate = self
        
        let isRoomSelected = roomId != ""
        RoomName.isEnabled = isRoomSelected
        RoomInfoButton.isEnabled = isRoomSelected
        RoomPartButton.isEnabled = isRoomSelected
        RoomEncryptionButton.isEnabled = isRoomSelected
        RoomInsertButton.isEnabled = isRoomSelected
        RoomMessageInput.textField.isEnabled = isRoomSelected
        RoomMessageInput.emojiButton.isEnabled = isRoomSelected
        RoomName.isHidden = !isRoomSelected
        RoomTopic.isHidden = !isRoomSelected

        ConnectivityBar.alphaValue = 0
        
        matrixNetworkConnectivityChanged(wifi: MatrixServices.inst.reachableViaWifi, wwan: MatrixServices.inst.reachableViaWwan)
    }
    
    func matrixNetworkConnectivityChanged(wifi: Bool, wwan: Bool) {
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            ConnectivityBar.animator().alphaValue = wifi || wwan ? 0 : 1
        }, completionHandler: {
            
        })
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
            if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
                room.sendEmote(String(unformattedText[startIndex...]), localEcho: &returnedEvent) { (response) in
                    if case .success( _) = response {
                        if let index = MatrixServices.inst.roomCaches[self.roomId]!.unfilteredContent.index(where: { $0.eventId == localReturnedEvent }) {
                            MatrixServices.inst.roomCaches[self.roomId]!.replace(returnedEvent!, at: index)
                        }
                    }
                    self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state)
                }
                MatrixServices.inst.roomCaches[roomId]!.append(returnedEvent!)
                localReturnedEvent = returnedEvent?.eventId ?? nil
                matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: roomId).state)
            }
        } else {
            var localReturnedEvent: String? = nil
            if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
                room.sendTextMessage(unformattedText, formattedText: formattedText, localEcho: &returnedEvent) { (response) in
                    if case .success( _) = response {
                        if let index = MatrixServices.inst.roomCaches[self.roomId]!.unfilteredContent.index(where: { $0.eventId == localReturnedEvent }) {
                            MatrixServices.inst.roomCaches[self.roomId]!.replace(returnedEvent!, at: index)
                        }
                    }
                    self.matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: self.roomId).state)
                }
                MatrixServices.inst.roomCaches[roomId]!.append(returnedEvent!)
                localReturnedEvent = returnedEvent?.eventId ?? nil
                matrixDidRoomMessage(event: returnedEvent!, direction: .forwards, roomState: MatrixServices.inst.session.room(withRoomId: roomId).state)
            }
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
            case "SegueToRoomActions":
                if let dest = segue.destinationController as? PopoverRoomActions {
                    dest.roomId = roomId
                }
                break
            default:
                return
            }
        }
    }

    func uiRoomNeedsCryptoReload() {
       /* for view in RoomMessageTableView.subviews {
            for cell in view.subviews {
                if let message = cell as? RoomMessage {
                    message.drawnEventHash = 0
                    message.updateIcon()
                    message.needsLayout = true
                }
            }
        } */
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
        guard cacheEntry.roomId != roomId else {
            updateRoomControls(withCacheEntry: entry)
            return
        }
    
        roomTyping = false
        roomIsPaginating = false
        roomIsOverscrolling = false
        
        roomId = cacheEntry.roomId
        if let cache = MatrixServices.inst.roomCaches[roomId] {
           // cache.managedTable = RoomMessageTableView
           // cache.managedTable!.roomId = roomId
 
            if cacheEntry.encrypted() {
                RoomMessageInput.textField.placeholderString = "Encrypted message"
                RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockLockedTemplate)
            } else {
                RoomMessageInput.textField.placeholderString = "Message"
                RoomEncryptionButton.image = NSImage(named: NSImage.Name.lockUnlockedTemplate)
            }
            
            let roomDidPaginate = {
               /* OperationQueue.main.addOperation({
                    self.RoomMessageTableView.scrollRowToVisible(row: cache.filteredContent.count-1, animated: false)
                    self.RoomMessageInput.window?.makeFirstResponder(self.RoomMessageInput.textField)
                }) */
            }
            
            if cache.filteredContent.count >= 50 {
                roomDidPaginate()
            } else {
                if cache.filteredContent.count == 0 {
                    if let room = MatrixServices.inst.session.room(withRoomId: cacheEntry.roomId) {
                        room.liveTimeline.resetPagination()
                        if room.liveTimeline.canPaginate(.backwards) {
                            room.liveTimeline.paginate(50, direction: .backwards, onlyFromStore: false) { _ in
                                roomDidPaginate()
                            }
                        }
                    }
                }
            }
        }
        
        RoomMessageView.reload()
        updateRoomControls(withCacheEntry: entry)
    }
    
    func updateRoomControls(withEvent event: MXEvent? = nil, withCacheEntry entry: RoomListEntry? = nil) {
        if event != nil {
            guard roomId == event!.roomId else { return }
        }
        
        var isInvite = false
        var isParted = false
        var isKicked = false
        
        if entry != nil {
            if let cacheEntry = entry!.roomsCacheEntry {
                isInvite = cacheEntry.isInvite()
                
                RoomName.stringValue = cacheEntry.roomDisplayName
                RoomTopic.stringValue = cacheEntry.roomTopic
            }
        }
        
        if event != nil {
            if event!.type == "m.room.member" {
                guard event!.roomId == roomId else { return }
                guard event!.stateKey == MatrixServices.inst.session.myUser.userId else { return }
                
                let new = event!.content.keys.contains("membership") ? event!.content["membership"] as! String : "join"
                var old = new == "join" ? "leave" : "join"
                if event!.prevContent != nil {
                    old = event!.prevContent.keys.contains("membership") ? event!.prevContent["membership"] as! String : new == "join" ? "leave" : "join"
                }
                
                if new == "leave" && old != "leave" {
                    if event!.stateKey == event!.sender {
                        isParted = true
                    } else {
                        isKicked = true
                    }
                }
            }
        }
        
        RoomName.isEnabled = true
        RoomName.isHidden = false
        RoomTopic.isEnabled = true
        RoomTopic.isHidden = false
        
        RoomInviteLabel.isHidden = !isParted && !isKicked && !isInvite
        if isParted {
            RoomInviteLabel.stringValue = "You left this room"
        } else if isKicked {
            RoomInviteLabel.stringValue = "You were kicked from this room"
        } else if isInvite {
            RoomInviteLabel.stringValue = "You are invited to this room"
        } else {
            RoomInviteLabel.stringValue = "You are not joined to this room"
        }
        
        RoomInviteAcceptButton.isHidden = !isInvite
        RoomInviteAcceptButton.isEnabled = isInvite
        
        RoomInviteDeclineButton.isHidden = !isInvite
        RoomInviteDeclineButton.isEnabled = isInvite
        
        RoomMessageInput.isHidden = isInvite || isParted || isKicked
        RoomMessageInput.textField.isEnabled = !isParted && !isKicked && !isInvite
        RoomMessageInput.emojiButton.isEnabled = !isParted && !isKicked && !isInvite
        
        RoomInsertButton.isHidden = isInvite || isParted || isKicked
        RoomInsertButton.isEnabled = !isParted && !isKicked && !isInvite
        
        RoomInfoButton.isEnabled = !isParted && !isKicked
        RoomPartButton.isEnabled = !isParted && !isKicked && !isInvite
        RoomEncryptionButton.isEnabled = !isParted && !isKicked && !isInvite
    }
    
    func matrixDidRoomMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState) {
        guard event.roomId == roomId else { return }
        guard MatrixServices.inst.roomCaches[roomId]!.filteredContent.contains(where: { $0.eventId == event.eventId }) else { return }
        
        switch event.type {
        case "m.typing":
            return
        case "m.receipt":
            return
        case "m.room.message":
            do {
                let str = NSString(data: try JSONSerialization.data(
                    withJSONObject: event.clear.jsonDictionary() ?? [:],
                    options: JSONSerialization.WritingOptions.prettyPrinted),
                    encoding: String.Encoding.utf8.rawValue
                )! as String
                print(str)
                let append = direction == .forwards ? "true" : "false"
                let script = "drawEvents([\(str)], \(append));"
                RoomMessageView.evaluateJavaScript(script) { (result, error) in
                    if error != nil {
                        print("Javascript error occured in webView:didFinish: \(error!.localizedDescription)")
                        print("Script: \(script)")
                    }
                }
            } catch {
                print("Javascript exception occured in webView:didFinish: \(error.localizedDescription)")
                print("Script not available")
            }
            
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
    
    func matrixDidRoomUserJoin(event: MXEvent) {
        guard event.roomId == roomId else { return }
        guard event.stateKey == MatrixServices.inst.session.myUser.userId else { return }
        
        updateRoomControls(withEvent: event)
    }
    
    func matrixDidRoomUserPart(event: MXEvent) {
        guard event.roomId == roomId else { return }
        guard event.stateKey == MatrixServices.inst.session.myUser.userId else { return }

        updateRoomControls(withEvent: event)
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
