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

class MainViewJoinController: NSViewController {
    @IBOutlet weak var CreateRoomButton: NSButton!
    @IBOutlet weak var CreateRoomSpinner: NSProgressIndicator!
    @IBOutlet weak var CreateRoomDisableFederationCheckbox: NSButton!
    @IBOutlet weak var JoinRoomButton: NSButton!
    @IBOutlet weak var JoinRoomSpinner: NSProgressIndicator!
    @IBOutlet weak var JoinRoomText: NSTextField!
    
    var controls: [NSControl] = []

    override func viewDidLoad() {
        controls = [ CreateRoomButton, JoinRoomButton,
                     JoinRoomText, CreateRoomDisableFederationCheckbox ]
        for control in controls {
            control.isEnabled = true
        }
        super.viewDidLoad()
    }
    
    @IBAction func createRoomButtonClicked(_ sender: NSButton) {
        for control in controls {
            control.isEnabled = false
        }
        CreateRoomSpinner.startAnimation(sender)
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            CreateRoomButton.animator().alphaValue = 0
            CreateRoomSpinner.alphaValue = 1
        }, completionHandler: {
            MatrixServices.inst.session.createRoom(parameters: [:]) { (response) in
                if response.isFailure, let error = response.error {
                    let alert = NSAlert()
                    alert.messageText = "Failed to create room"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                sender.window?.contentViewController?.dismiss(sender)
            }
        })
    }

    @IBAction func joinRoomButtonClicked(_ sender: NSButton) {
        let room = self.JoinRoomText.stringValue
        if !(room.starts(with: "#") || room.starts(with: "!")) || !room.contains(":") {
            return
        }
        for control in controls {
            control.isEnabled = false
        }
        JoinRoomSpinner.startAnimation(sender)
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            JoinRoomButton.animator().alphaValue = 0
            JoinRoomSpinner.alphaValue = 1
        }, completionHandler: {
            MatrixServices.inst.session.joinRoom(room, completion: { (response) in
                if response.isFailure, let error = response.error {
                    let alert = NSAlert()
                    alert.messageText = "Failed to join room \(room)"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                sender.window?.contentViewController?.dismiss(sender)
            })
        })
    }
}
