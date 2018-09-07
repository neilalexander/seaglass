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

class MainViewInviteController: NSViewController {

    @IBOutlet weak var InviteeMatrixID: NSTextField!
    @IBOutlet weak var InviteButton: NSButton!
    @IBOutlet weak var CancelButton: NSButton!
    @IBOutlet weak var InviteSpinner: NSProgressIndicator!
    
    var roomId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for control in [ InviteeMatrixID, InviteButton, CancelButton ] as [NSControl] {
            control.isEnabled = true
        }
        InviteSpinner.isHidden = true
    }
    
    @IBAction func inviteButtonClicked(_ sender: NSButton) {
        guard sender == InviteButton else { return }
        guard roomId != "" else { return }
        
        let invitee = MXRoomInvitee.userId(String(InviteeMatrixID.stringValue).trimmingCharacters(in: .whitespacesAndNewlines))
        
        for control in [ InviteeMatrixID, InviteButton, CancelButton ] as [NSControl] {
            control.isEnabled = false
        }
        InviteSpinner.isHidden = false
        InviteSpinner.startAnimation(self)
        
        let group = DispatchGroup()
        
        group.enter()
        MatrixServices.inst.session.room(withRoomId: roomId).invite(invitee) { (response) in
            if response.isFailure {
                let alert = NSAlert()
                alert.messageText = "Failed to invite user"
                alert.informativeText = response.error!.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            group.leave()
        }
        
        group.notify(queue: .main, execute: {
            self.InviteSpinner.isHidden = true
            self.InviteSpinner.stopAnimation(self)
            
            sender.window?.contentViewController?.dismiss(sender)
        })
    }
    
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        guard sender == CancelButton else { return }
        self.dismiss(sender)
    }
    
}
