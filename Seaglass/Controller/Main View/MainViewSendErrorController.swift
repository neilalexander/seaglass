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

class MainViewSendErrorController: NSViewController {
    @IBOutlet var ApplyAllCheckbox: NSButton!
    @IBOutlet var ErrorDescription: NSTextField!
    
    public var roomId: String?
    public var eventId: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func ignoreButtonClicked(_ sender: NSButton) {
        self.dismiss(sender)
    }
    
    @IBAction func deleteButtonClicked(_ sender: NSButton) {
        if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
            if ApplyAllCheckbox.state == .off {
                if let index = MatrixServices.inst.eventCache[roomId!]!.index(where: { $0.eventId == eventId }) {
                    let event = MatrixServices.inst.eventCache[roomId!]![index]
                    MatrixServices.inst.mainController?.channelDelegate?.matrixDidRoomMessage(event: event.prune(), direction: .forwards, roomState: room.state, replaces: eventId, removeOnReplace: true)
                    MatrixServices.inst.eventCache[roomId!]![index] = event.prune()
                }
            } else {
                for (index, event) in MatrixServices.inst.eventCache[roomId!]!.enumerated() {
                    if event.sentState == MXEventSentStateFailed {
                        let event = MatrixServices.inst.eventCache[roomId!]![index]
                        MatrixServices.inst.mainController?.channelDelegate?.matrixDidRoomMessage(event: event.prune(), direction: .forwards, roomState: room.state, replaces: eventId, removeOnReplace: true)
                        MatrixServices.inst.eventCache[roomId!]![index] = event.prune()
                    }
                }
            }
        }
        self.dismiss(sender)
    }
    
    @IBAction func sendAgainButtonClicked(_ sender: NSButton) {
        self.dismiss(sender)
    }
}
