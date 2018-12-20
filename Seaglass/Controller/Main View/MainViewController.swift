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

class MainViewController: NSSplitViewController, MatrixServicesDelegate {
    
    let defaults = UserDefaults.standard
    
    weak var roomsController: MainViewRoomsController?
    weak var channelController: MainViewRoomController?
    
    weak var servicesDelegate: MatrixServicesDelegate?
    weak var roomsDelegate: MatrixRoomsDelegate?
    weak var channelDelegate: MatrixRoomDelegate?
    
    var keyRequests: [MainViewKeyRequestController] = []

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        MatrixServices.inst.mainController = self
        
        roomsController = childViewControllers.compactMap({ return $0 as? MainViewRoomsController }).first
        channelController = childViewControllers.compactMap({ return $0 as? MainViewRoomController }).first
        
        roomsController?.mainController = self
        channelController?.mainController = self
        
        servicesDelegate = self
        roomsDelegate = roomsController
        channelDelegate = channelController
        
        super.viewDidLoad()
    }
    
    func matrixNetworkConnectivityChanged(wifi: Bool, wwan: Bool) {
        
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
        view.window?.close()
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            view.window?.animator().alphaValue = 0
        }, completionHandler: {
            NSApplication.shared.terminate(self)
        })
    }
    
    func matrixDidReceiveKeyRequest(_ request: MXIncomingRoomKeyRequest) {
        guard request.userId == MatrixServices.inst.session.myUser.userId else { return }
        guard (request.requestBody["sender_key"] as? String) != nil else { return }
        guard !keyRequests.contains(where: { $0.request!.deviceId == request.deviceId }) else { return }
        
        MatrixServices.inst.session.crypto.deviceList.downloadKeys([request.userId], forceDownload: false, success: { (devicemap) in
            if MatrixServices.inst.session.crypto.deviceList.storedDevice(request.userId, deviceId: request.deviceId) != nil {
                DispatchQueue.main.async {
                    let sheet = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("KeyRequest")) as! MainViewKeyRequestController
                    sheet.request = request
                    self.presentViewControllerAsSheet(sheet)
                    self.keyRequests.append(sheet)
                }
            }
        }) { (error) in
        }
    }
    
    func matrixDidReceiveKeyRequestCancellation(_ cancellation: MXIncomingRoomKeyRequestCancellation) {
        for (index, controller) in keyRequests.enumerated() {
            guard cancellation.deviceId == controller.request!.deviceId else { continue }
            guard cancellation.userId == controller.request!.userId else { continue }
            if controller.request!.requestId == cancellation.requestId {
                controller.dismiss(self)
                keyRequests.remove(at: index)
            }
        }
    }
    
    func matrixDidCompleteKeyRequest(_ request: MXIncomingRoomKeyRequest) {
        for (index, controller) in keyRequests.enumerated() {
            guard request.deviceId == controller.request!.deviceId else { continue }
            guard request.userId == controller.request!.userId else { continue }
            if controller.request!.requestId == request.requestId {
                keyRequests.remove(at: index)
            }
        }
    }
    
}
