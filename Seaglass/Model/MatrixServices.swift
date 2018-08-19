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

protocol ViewControllerWithDelegates {
    var roomsController: MainViewRoomsController? { get }
    var channelController: MainViewRoomController? { get }
    
    var servicesDelegate: MatrixServicesDelegate? { get }
    var roomsDelegate: MatrixRoomsDelegate? { get }
    var channelDelegate: MatrixRoomDelegate? { get }
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
    var eventCache: Dictionary<String, [MXEvent]> = [:]
    
    var mainController: ViewControllerWithDelegates?
    
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
    
    func start(_ credentials: MXCredentials, disableCache: Bool) {
        let options = MXSDKOptions.sharedInstance()
        options.enableCryptoWhenStartingMXSession = true
        
        print("Creating REST client")
        client = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)
        
        print("Creating session")
        session = MXSession(matrixRestClient: client)
        
        state = .starting
        
        if disableCache {
            print("Disabling cache")
            fileStore = MXNoStore()
        } else {
            print("Enabling cache")
            fileStore = MXFileStore()
        }

        session.setStore(fileStore) { response in
            if case .failure(let error) = response {
                print("An error occurred setting the store: \(error)")
                return
            }
            
            self.state = .starting
            
            if self.session.crypto != nil {
                self.session.crypto.warnOnUnknowDevices = false
            }
            
            self.session.start { response in
                guard response.isSuccess else {
                    print("Assertion failed: setStore response was not true")
                    return
                }
                
                DispatchQueue.main.async {
                    print("Handing off to services delegate")
                    self.state = .started
                    self.mainController?.servicesDelegate?.matrixDidLogin(self.session);
                }
                
                DispatchQueue.main.async {
                    self.sessionListener = self.session.listenToEvents([.roomMember], { (event, direction, roomState) in
                        switch event.type {
                        case "m.room.member":
                            if event.stateKey != MatrixServices.inst.session.myUser.userId {
                                return
                            }
                            if direction != .forwards {
                                return
                            }
                            switch event.content["membership"] as? String {
                            case "join":
                                if let room = MatrixServices.inst.session.room(withRoomId: event.roomId) {
                                    if self.mainController?.roomsDelegate?.matrixIsRoomKnown(room) == false {
                                        self.mainController?.roomsDelegate?.matrixDidJoinRoom(room)
                                    }
                                }
                                return
                            case "invite":
                               // print("Invited to room \(event.roomId)")
                                return
                            case "leave":
                                if let room = MatrixServices.inst.session.room(withRoomId: event.roomId) {
                                    if self.mainController?.roomsDelegate?.matrixIsRoomKnown(room) == true {
                                        self.mainController?.roomsDelegate?.matrixDidPartRoom(room)
                                    }
                                }
                                return
                            default:
                               // print(event)
                               // print(direction)
                               // print("")
                                return
                            }
                        default:
                            return
                        }
                    }) as? MXSessionEventListener
                }
            }
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
    
    func subscribeToRoom(roomId: String) {
        guard let room = self.session.room(withRoomId: roomId) else { return }
        if eventListeners[roomId] != nil {
            return
        }
        
        eventListeners[roomId] = room.liveTimeline.listenToEvents() { (event, direction, roomState) in
            if event.roomId == nil {
                return
            }
            if event.roomId == "" {
                return
            }
            if !self.eventCache.keys.contains(event.roomId) {
                self.eventCache[event.roomId] = []
            }
            let cacheTypes = [ "m.room.create", "m.room.message", "m.room.name", "m.room.member", "m.room.topic", "m.room.avatar", "m.room.canonical_alias" ]
            switch event.type {
            case "m.room.redaction":
                for e in self.eventCache[event.roomId]!.filter({ $0.eventId == event.redacts }) {
                    if let index = self.eventCache[event.roomId]!.index(of: e) {
                        self.mainController?.channelDelegate?.matrixDidRoomMessage(event: e.prune(), direction: direction, roomState: roomState, replaces: event.redacts!);
                        self.eventCache[event.roomId]![index] = e.prune()
                    }
                }
                break
            default:
                if !cacheTypes.contains(event.type) {
                    return
                }
                if !self.eventCache[event.roomId]!.contains(where: { $0.eventId == event.eventId }) {
                    if direction == .forwards {
                        self.eventCache[event.roomId]!.append(event)
                    } else {
                        self.eventCache[event.roomId]!.insert(event, at: 0)
                    }
                    self.mainController?.channelDelegate?.matrixDidRoomMessage(event: event, direction: direction, roomState: roomState, replaces: nil);
                    self.mainController?.roomsDelegate?.matrixDidUpdateRoom(room)
                } else {
                    if let index = self.eventCache[event.roomId]!.index(of: event) {
                        let original = self.eventCache[event.roomId]![index].eventId
                        self.eventCache[event.roomId]![index] = event
                        self.mainController?.channelDelegate?.matrixDidRoomMessage(event: event, direction: direction, roomState: roomState, replaces: original);
                        self.mainController?.roomsDelegate?.matrixDidUpdateRoom(room)
                    }
                }
                break
            }
        } as? MXEventListener
        
        room.liveTimeline.resetPagination()
        room.liveTimeline.paginate(100, direction: .backwards, onlyFromStore: false) { _ in
            // complete?
        }
    }
    
    func userHasPower(inRoomId: String, forEvent: String) -> Bool {
        let room = session.room(withRoomId: inRoomId)
        if room == nil {
            return false
        }
        if room!.state.powerLevels == nil {
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
