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

class RoomPowerLevelsController: NSViewController {
    
    @IBOutlet var PowerLevelDefault: NSTextField!
    @IBOutlet var PowerLevelSendMessage: NSTextField!
    @IBOutlet var PowerLevelInvite: NSTextField!
    @IBOutlet var PowerLevelConfigure: NSTextField!
    @IBOutlet var PowerLevelKick: NSTextField!
    @IBOutlet var PowerLevelBan: NSTextField!
    @IBOutlet var PowerLevelRedactOther: NSTextField!
    @IBOutlet var PowerLevelNotifyAll: NSTextField!
    @IBOutlet var PowerLevelChangeName: NSTextField!
    @IBOutlet var PowerLevelChangeAvatar: NSTextField!
    @IBOutlet var PowerLevelChangeCanonicalAlias: NSTextField!
    @IBOutlet var PowerLevelChangeHistory: NSTextField!
    @IBOutlet var PowerLevelChangeJoinRule: NSTextField!
    @IBOutlet var PowerLevelChangeTopic: NSTextField!
    @IBOutlet var PowerLevelChangeWidgets: NSTextField!
    
    var roomId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if roomId != "" {
            let room = MatrixServices.inst.session.room(withRoomId: roomId)
            
            PowerLevelDefault.integerValue = room!.state.powerLevels.usersDefault
            PowerLevelSendMessage.integerValue = room!.state.powerLevels.eventsDefault
            PowerLevelInvite.integerValue = room!.state.powerLevels.invite
           // PowerLevelConfigure.stringValue = room?.state.powerLevels.
            PowerLevelKick.integerValue = room!.state.powerLevels.kick
            PowerLevelBan.integerValue = room!.state.powerLevels.ban
            PowerLevelRedactOther.integerValue = room!.state.powerLevels.redact
           // PowerLevelNotifyAll.stringValue = room?.state.powerLevels.
           // PowerLevelChangeName.stringValue = room?.state.powerLevels.
           // PowerLevelChangeAvatar.stringValue = room?.state.powerLevels.
           // PowerLevelChangeCanonicalAlias.stringValue = room?.state.powerLevels
           // PowerLevelChangeHistory.stringValue = room?.state.powerLevels.
           // PowerLevelChangeJoinRule.stringValue = room?.state.powerLevels.
           // PowerLevelChangeTopic.stringValue = room?.state.powerLevels.
           // PowerLevelChangeWidgets.stringValue = room?.state.powerLevels.
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        
        if PowerLevelDefault.integerValue != room!.state.powerLevels.usersDefault {
           // room!.
        }
    }
    
}
