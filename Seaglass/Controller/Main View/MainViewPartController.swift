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

class MainViewPartController: NSViewController {
    @IBOutlet weak var LeaveButton: NSButton!
    @IBOutlet weak var LeaveSpinner: NSProgressIndicator!
    
    var roomId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LeaveButton.isEnabled = roomId != ""
    }
    
    @IBAction func leaveButtonClicked(_ sender: NSButton) {
        if roomId == "" {
            return
        }
        
        LeaveButton.isEnabled = false
        LeaveSpinner.startAnimation(sender)
        
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            LeaveButton.animator().alphaValue = 0
            LeaveSpinner.animator().alphaValue = 1
        }, completionHandler: {
            MatrixServices.inst.session.leaveRoom(self.roomId) { (response) in
                if response.isFailure {
                    let alert = NSAlert()
                    alert.messageText = "Failed to leave room \(self.roomId)"
                    alert.informativeText = response.error!.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                sender.window?.contentViewController?.dismiss(sender)
            }
        })
    }
}
