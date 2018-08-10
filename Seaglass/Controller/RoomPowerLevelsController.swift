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
            
            print(room!.state.powerLevels.events)
            
            PowerLevelDefault.integerValue = room?.state.powerLevels.usersDefault ?? 0
            PowerLevelSendMessage.integerValue = room?.state.powerLevels.eventsDefault ?? 0
            PowerLevelInvite.integerValue = room?.state.powerLevels.invite ?? 0
            PowerLevelConfigure.integerValue = room?.state.powerLevels.events["m.room.power_levels"] as? Int ?? 50
            PowerLevelKick.integerValue = room?.state.powerLevels.kick ?? 50
            PowerLevelBan.integerValue = room?.state.powerLevels.ban ?? 50
            PowerLevelRedactOther.integerValue = room?.state.powerLevels.redact ?? 50
           // PowerLevelNotifyAll.integerValue = room?.state.powerLevels. ?? 50
            PowerLevelChangeName.integerValue = room?.state.powerLevels.events["m.room.name"] as? Int ?? 50
            PowerLevelChangeAvatar.integerValue = room?.state.powerLevels.events["m.room.avatar"] as? Int ?? 50
            PowerLevelChangeCanonicalAlias.integerValue = room?.state.powerLevels.events["m.room.canonical_alias"] as? Int ?? 50
            PowerLevelChangeHistory.integerValue = room?.state.powerLevels.events["m.room.history_visibility"] as? Int ?? 100
           // PowerLevelChangeJoinRule.integerValue = room?.state.powerLevels. ?? 100
            PowerLevelChangeTopic.integerValue = room?.state.powerLevels.events["m.room.topic"] as? Int ?? 50
            PowerLevelChangeWidgets.integerValue = room?.state.powerLevels.events["im.vector.modular.widgets"] as? Int ?? 50
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        
        if PowerLevelDefault.integerValue != room!.state.powerLevels.usersDefault {
           // room!.
        }
    }
    
}
