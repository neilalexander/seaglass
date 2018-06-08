//
//  MainViewController.swift
//  Matrix
//
//  Created by Neil Alexander on 05/06/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

protocol MatrixServicesDelegate: AnyObject {
    func matrixDidLogin(_ session: MXSession)
    func matrixWillLogout()
    func matrixDidLogout()
}

protocol MatrixRoomsDelegate: AnyObject {
    func matrixDidJoinRoom(_ room: MXRoom)
    func matrixDidPartRoom()
    func matrixDidUpdateRoom()
}

protocol MatrixChannelDelegate: AnyObject {
    func uiDidSelectChannel(entry: ChannelListEntry)
    func matrixDidChannelMessage(event: MXEvent, direction: MXTimelineDirection, roomState: MXRoomState)
    func matrixDidChannelUserJoin()
    func martixDidChannelUserPart()
}

class MainViewController: NSSplitViewController, MatrixServicesDelegate, ViewControllerWithDelegates {
    
    let defaults = UserDefaults.standard
    
    weak var roomsController: MainViewRoomsController?
    weak var channelController: MainViewChannelController?
    
    weak var servicesDelegate: MatrixServicesDelegate?
    weak var roomsDelegate: MatrixRoomsDelegate?
    weak var channelDelegate: MatrixChannelDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        MatrixServices.inst.mainController = self
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        roomsController = self.childViewControllers.compactMap({ return $0 as? MainViewRoomsController }).first!
        channelController = self.childViewControllers.compactMap({ return $0 as? MainViewChannelController }).first!
        
        roomsController?.mainController = self
        channelController?.mainController = self
        
        super.viewWillAppear()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        servicesDelegate = self
        roomsDelegate = roomsController
        channelDelegate = channelController
        
        self.view.window?.title = "Matrix Client"
        self.view.window?.styleMask.update(with: .closable)
        self.view.window?.styleMask.update(with: .miniaturizable)
        self.view.window?.styleMask.update(with: .resizable)

        for room in MatrixServices.inst.session.rooms {
            roomsDelegate?.matrixDidJoinRoom(room)
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func matrixDidLogin(_ session: MXSession) {
    }
    
    func matrixWillLogout() {
        defaults.set(false, forKey: "LoginAutomatically")
        defaults.removeObject(forKey: "AccessToken")
        defaults.removeObject(forKey: "HomeServer")
        defaults.removeObject(forKey: "UserID")
    }
    
    func matrixDidLogout() {
        self.view.window?.endSheet(self.view.window!.attachedSheet!)
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            self.view.window?.animator().alphaValue = 0
        }, completionHandler: {
            NSApplication.shared.terminate(self)
        })
    }

}
