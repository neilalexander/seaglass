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
import AFNetworking

protocol MatrixServicesDelegate: AnyObject {
    func matrixDidLogin(_ session: MXSession)
    func matrixWillLogout()
    func matrixDidLogout()
    func matrixDidReceiveKeyRequest(_ request: MXIncomingRoomKeyRequest)
    func matrixDidReceiveKeyRequestCancellation(_ cancellation: MXIncomingRoomKeyRequestCancellation)
    func matrixDidCompleteKeyRequest(_ request: MXIncomingRoomKeyRequest)
    func matrixNetworkConnectivityChanged(wifi: Bool, wwan: Bool)
}

protocol MatrixRoomsDelegate: AnyObject {
    func matrixDidJoinRoom(_ room: MXRoom)
    func matrixDidPartRoom(_ room: MXRoom)
    func matrixDidUpdateRoom(_ room: MXRoom)
    func matrixIsRoomKnown(_ room: MXRoom) -> Bool
    func matrixNetworkConnectivityChanged(wifi: Bool, wwan: Bool)
}

protocol MatrixRoomDelegate: AnyObject {
    var roomId: String { get }
    func uiDidSelectRoom(entry: RoomListEntry)
    func uiRoomNeedsCryptoReload()
    func uiRoomStartInvite()
    func matrixDidRoomMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState)
    func matrixDidRoomUserJoin(event: MXEvent)
    func matrixDidRoomUserPart(event: MXEvent)
    func matrixNetworkConnectivityChanged(wifi: Bool, wwan: Bool)
}

class MatrixServices: NSObject {
    static let inst = MatrixServices()
    static let credKey = "Matrix"
    
    enum State {
        case needsCredentials, notStarted, starting, started
    }
    private(set) var state: State
    
    // From the Matrix SDK
    var client: MXRestClient!
    var session: MXSession!
    var fileStore: MXStore!
    
    // Own structures
    var sessionListener: MXSessionEventListener?
    var eventListeners: Dictionary<String, MXEventListener> = [:]
    var roomCaches: Dictionary<String, MatrixRoomCache> = [:]
    var avatarCache: Dictionary<String, NSImage> = [:]
    
    // Network reachability
    var reachable: Bool {
        get {
            return reachableViaWifi || reachableViaWwan
        }
    }
    var reachableViaWifi: Bool = true
    var reachableViaWwan: Bool = true
    
    var mainController: MainViewController?
    
    var credentials: MXCredentials? {
        didSet {
            guard
                let homeServerURL = credentials?.homeServer,
                let userId = credentials?.userId,
                let accessToken = credentials?.accessToken,
                let deviceId = credentials?.deviceId
                else { UserDefaults.standard.removeObject(forKey: MatrixServices.credKey); return }
            
            let storedCredentials: [String: String] = [
                "homeServer": homeServerURL,
                "userId": userId,
                "token": accessToken,
                "deviceId": deviceId
            ]

            UserDefaults.standard.set(storedCredentials, forKey: MatrixServices.credKey)
            UserDefaults.standard.synchronize()
            
            if state == .needsCredentials {
                state = .notStarted
            }
        }
    }
    
    override init() {
        if  let savedCredentials = UserDefaults.standard.dictionary(forKey: MatrixServices.credKey),
            let homeServer = savedCredentials["homeServer"] as? String,
            let userId = savedCredentials["userId"] as? String,
            let token = savedCredentials["token"] as? String,
            let deviceId = savedCredentials["deviceId"] as? String {
            
            credentials = MXCredentials(homeServer: homeServer, userId: userId, accessToken: token)
            credentials?.deviceId = deviceId
            state = .notStarted
        } else {
            state = .needsCredentials
            credentials = nil
        }
    }
    
    func didStart(_ response: MXResponse<Void>, success: (() -> Void)?, failure: (() -> Void)?) -> Void {
        guard response.isSuccess else {
            print("Open session failed: \(response.error!.localizedDescription), trying again in 5 seconds...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.session.start(completion: { (response) in
                    self.didStart(response, success: success, failure: failure)
                    if response.isSuccess {
                        success?()
                    } else {
                        failure?()
                    }
                })
            }
            return
        }
        print("Opening session...")
        
        if self.session.crypto != nil {
            self.session.crypto.warnOnUnknowDevices = UserDefaults.standard.bool(forKey: "CryptoParanoid")
        }
        
        DispatchQueue.main.async {
            print("Handing off to services delegate")
            self.state = .started
            self.mainController?.servicesDelegate?.matrixDidLogin(self.session);
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.mxCryptoRoomKeyRequest, object: self.session.crypto, queue: OperationQueue.main, using: { (notification) in
            guard self.state == .started else { return }
            self.mainController?.servicesDelegate?.matrixDidReceiveKeyRequest(notification.userInfo?.first?.value as! MXIncomingRoomKeyRequest)
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.mxCryptoRoomKeyRequestCancellation, object: self.session.crypto, queue: OperationQueue.main, using: { (notification) in
            guard self.state == .started else { return }
            self.mainController?.servicesDelegate?.matrixDidReceiveKeyRequestCancellation(notification.userInfo?.first?.value as! MXIncomingRoomKeyRequestCancellation)
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AFNetworkingReachabilityDidChange, object: nil, queue: OperationQueue.main, using: { (notification) in
            guard self.state == .started else { return }
            
            if let reachability = notification.userInfo?[AFNetworkingReachabilityNotificationStatusItem] as? AFNetworkReachabilityStatus.RawValue {
                self.reachableViaWifi = reachability == AFNetworkReachabilityStatus.reachableViaWiFi.rawValue
                self.reachableViaWwan = reachability == AFNetworkReachabilityStatus.reachableViaWWAN.rawValue
            
                print("Network connectivity changed (Wi-Fi: \(self.reachableViaWifi), WWAN: \(self.reachableViaWwan))")
                
                self.mainController?.servicesDelegate?.matrixNetworkConnectivityChanged(wifi: self.reachableViaWifi, wwan: self.reachableViaWwan)
                self.mainController?.roomsDelegate?.matrixNetworkConnectivityChanged(wifi: self.reachableViaWifi, wwan: self.reachableViaWwan)
                self.mainController?.channelDelegate?.matrixNetworkConnectivityChanged(wifi: self.reachableViaWifi, wwan: self.reachableViaWwan)
                
                if self.reachable {
                    self.client.sync(fromToken: nil, serverTimeout: 5000, clientTimeout: 5000, setPresence: nil, completion: { (response) in
                        if response.isFailure {
                            print("Sync error: \(response.error!.localizedDescription)")
                        }
                    })
                }
            }
        })
        
        self.sessionListener = self.session.listenToEvents([.roomMember, .roomThirdPartyInvite], { (event, direction, roomState) in
            switch event.type {
            case "m.room.member":
                guard event.stateKey == MatrixServices.inst.session.myUser.userId else { return }
                guard direction == .forwards else { return }
                
                let new = event.content.keys.contains("membership") ? event.content["membership"] as! String : "join"
                var old = "leave"
                if event.prevContent != nil {
                    old = event.prevContent.keys.contains("membership") ? event.prevContent["membership"] as! String : "leave"
                }
                
                guard new != old else { return }
                
                switch new {
                case "join":
                    if let room = MatrixServices.inst.session.room(withRoomId: event.roomId) {
                        if self.mainController?.roomsDelegate?.matrixIsRoomKnown(room) == false {
                            self.mainController?.roomsDelegate?.matrixDidJoinRoom(room)
                        }
                    }
                    return
                case "invite":
                    if let room = MatrixServices.inst.session.room(withRoomId: event.roomId) {
                        if self.mainController?.roomsDelegate?.matrixIsRoomKnown(room) == false {
                            self.mainController?.roomsDelegate?.matrixDidJoinRoom(room)
                            
                            MatrixServices.inst.session.peek(inRoom: event.roomId, completion: { (response) in
                                guard !response.isFailure else { return }
                                
                                room.liveTimeline.resetPagination()
                                room.liveTimeline.paginate(100, direction: .backwards, onlyFromStore: false) { _ in
                                    // complete?
                                }
                            })
                        }
                    }
                    return
                case "leave":
                    if let room = MatrixServices.inst.session.room(withRoomId: event.roomId) {
                        if self.mainController?.roomsDelegate?.matrixIsRoomKnown(room) == true {
                            self.mainController?.roomsDelegate?.matrixDidPartRoom(room)
                        }
                    }
                    return
                default:
                    print(event)
                    print(direction)
                    print("")
                    return
                }
            default:
                print(event)
                print(direction)
                print("")
                return
            }
        }) as? MXSessionEventListener
    }
    
    func start(_ credentials: MXCredentials, disableCache: Bool, success: (() -> Void)?, failure: (() -> Void)?) {
        let options = MXSDKOptions.sharedInstance()
        options.enableCryptoWhenStartingMXSession = true
        
        if client == nil {
            print("Creating REST client")
            client = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)
        }
        
        if session == nil {
            print("Creating session")
            session = MXSession(matrixRestClient: client)
        }
        
        state = .starting
        
        if fileStore == nil {
            if disableCache {
                print("Disabling cache")
                fileStore = MXNoStore()
            } else {
                print("Enabling cache")
                fileStore = MXFileStore()
            }
        }
        
        session.setStore(fileStore) { response in
            print("Setting store...")
            if case .failure(let error) = response {
                print("Set store failed: \(error.localizedDescription), trying again in 5 seconds...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.start(credentials, disableCache: disableCache, success: success, failure: failure)
                }
                return
            }
            
            self.session.start(completion: { (response) in
                self.didStart(response, success: success, failure: failure)
                if response.isSuccess {
                    success?()
                } else {
                    failure?()
                }
            })
        }
    }
    
    func close() {
        client?.close()
    }
    
    func logout() {
        if session == nil {
            return
        }
        
        self.mainController?.servicesDelegate?.matrixWillLogout()
        
        UserDefaults.standard.removeObject(forKey: MatrixServices.credKey)
        UserDefaults.standard.synchronize()
        self.credentials = nil
        self.state = .needsCredentials
        
        session.logout { _ in
            MXFileStore().deleteAllData()
            self.mainController?.servicesDelegate?.matrixDidLogout()
        }
    }
    
    func selectRoom(roomId: String) {
        
    }
    
    @objc func eventDidDecrypt(_ notification: NSNotification) {
        if let event = notification.object as? MXEvent {
            if event.roomId != nil {
                if let cache = MatrixServices.inst.roomCaches[event.roomId] {
                    cache.update(event)
                }
            }
        }
    }
    
    func subscribeToRoom(roomId: String) {
        guard let room = self.session.room(withRoomId: roomId) else { return }
        guard eventListeners[roomId] == nil else { return }
        
        if !roomCaches.keys.contains(roomId) {
            roomCaches[roomId] = MatrixRoomCache()
        }

        if room.state.isEncrypted {
            session.crypto.downloadKeys(room.state.members.compactMap { return $0.userId }, forceDownload: false, success: { (devicemap) in
                self.mainController?.channelDelegate?.uiRoomNeedsCryptoReload()
            }) { (error) in
                print("Failed to download keys for \(roomId): \(error!.localizedDescription)")
            }
        }
 
        eventListeners[roomId] = room.liveTimeline.listenToEvents() { (event, direction, roomState) in
            guard event.roomId != nil && event.roomId != "" else { return }
            guard self.mainController?.channelDelegate?.roomId == event.roomId else { return }
            
            if event.decryptionError != nil {
                NotificationCenter.default.addObserver(MatrixServices.inst, selector: #selector(self.eventDidDecrypt), name: NSNotification.Name.mxEventDidDecrypt, object: event)
            }

            switch event.type {
            case "m.room.redaction":
                for e in self.roomCaches[roomId]!.unfilteredContent.filter({ $0.eventId == event.redacts }) {
                    guard !e.isRedactedEvent() else { continue }
                    if let index = self.roomCaches[roomId]!.unfilteredContent.index(where: { $0.eventId == event.redacts }) {
                        let pruned = e.prune()!
                        self.roomCaches[roomId]!.replace(pruned, at: index)
                        self.mainController?.channelDelegate?.matrixDidRoomMessage(event: pruned, direction: direction, roomState: roomState)
                    }
                }
                break
            case "m.room.member":
                if direction == .forwards {
                    let new = event.content.keys.contains("membership") ? event.content["membership"] as! String : "join"
                    var old = new == "join" ? "leave" : "join"
                    if event.prevContent != nil {
                        old = event.prevContent.keys.contains("membership") ? event.prevContent["membership"] as! String : new == "join" ? "leave" : "join"
                    }
                    
                    if new == "leave" && old != "leave" {
                        self.mainController?.channelDelegate?.matrixDidRoomUserPart(event: event)
                    } else if new == "join" && old != "join" {
                        self.mainController?.channelDelegate?.matrixDidRoomUserJoin(event: event)
                    }
                }
                fallthrough
            default:
                if !self.roomCaches[roomId]!.unfilteredContent.contains(where: { $0.eventId == event.eventId }) {
                    if direction == .forwards {
                        self.roomCaches[roomId]!.append(event)
                    } else {
                        self.roomCaches[roomId]!.insert(event, at: 0)
                    }
                } else {
                    if let index = self.roomCaches[roomId]!.unfilteredContent.index(where: { $0.eventId == event.eventId }) {
                        self.roomCaches[roomId]!.replace(event, at: index)
                    }
                }
                self.mainController?.channelDelegate?.matrixDidRoomMessage(event: event, direction: direction, roomState: roomState);
                self.mainController?.roomsDelegate?.matrixDidUpdateRoom(room)
                break
            }
        } as? MXEventListener
    }
    
    func userHasPower(inRoomId: String, forEvent: String) -> Bool {
        let room = session.room(withRoomId: inRoomId)
        if room == nil {
            return false
        }
        if room!.state.powerLevels == nil {
            return false
        }
        if session.invitedRooms().contains(where: { $0.roomId == inRoomId }) {
            return false
        }
        let powerLevel = { () -> Int in
            if room!.state.powerLevels.events.count == 0 {
                return room!.state.powerLevels.stateDefault
            }
            if room!.state.powerLevels.events.contains(where: { (arg) -> Bool in arg.key as? String == forEvent }) {
                return room!.state.powerLevels.events[forEvent] as! Int
            }
            return room!.state.powerLevels.stateDefault
        }()
        return room!.state.powerLevels.powerLevelOfUser(withUserID: session.myUser.userId) >= powerLevel
    }
}
