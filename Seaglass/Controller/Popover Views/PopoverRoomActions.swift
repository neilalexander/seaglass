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

class PopoverRoomActions: NSViewController {
    
    @IBOutlet weak var InviteButton: NSButton!
    @IBOutlet weak var AttachButton: NSButton!
    @IBOutlet weak var CallButton: NSButton!
    @IBOutlet weak var VideoButton: NSButton!
    
    var roomId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func inviteButtonClicked(_ sender: NSButton) {
        MatrixServices.inst.mainController?.channelDelegate?.uiRoomStartInvite()
        self.dismiss(sender)
    }
    
    @IBAction func attachButtonClicked(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.runModal()

        /*if let path = panel.url {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, path.pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    var event: MXEvent?
                    if let room = MatrixServices.inst.session.room(withRoomId: roomId) {
                        if UTTypeConformsTo(uti, kUTTypeImage) {
                            room.sendImage(data: <#T##Data#>, size: <#T##CGSize#>, mimeType: <#T##String#>, thumbnail: <#T##MXImage?#>, localEcho: &<#T##MXEvent?#>) { (<#MXResponse<String?>#>) in
                                print(response)
                            }
                        } else {
                            room.sendFile(localURL: path, mimeType: mimetype as String, localEcho: &event) { (response) in
                                print(response)
                            }
                        }
                    }
                }
            }
        }*/
    }
}
