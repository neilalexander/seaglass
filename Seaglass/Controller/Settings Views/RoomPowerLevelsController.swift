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
    @IBOutlet var PowerLevelChangePowerLevels: NSTextField!
    
    @IBOutlet var PowerLevelSaveButton: NSButton!
    
    var roomId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let controls = [ PowerLevelDefault, PowerLevelSendMessage, PowerLevelInvite,
                         PowerLevelKick, PowerLevelBan, PowerLevelRedactOther,
                         /*PowerLevelNotifyAll,*/ PowerLevelChangeName, PowerLevelChangeAvatar,
                         PowerLevelChangeCanonicalAlias, PowerLevelChangeHistory, PowerLevelChangeHistory,
                         /* PowerLevelChangeJoinRule,*/ PowerLevelChangeTopic, PowerLevelChangeWidgets,
                         PowerLevelChangePowerLevels, PowerLevelSaveButton ] as [NSControl]
        
        for control in controls {
            control.isEnabled = false
        }
        
        if roomId != "" {
            guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return }
            guard let powerLevels = room.state.powerLevels else { return }
            
            PowerLevelDefault.integerValue = powerLevels.usersDefault
            PowerLevelSendMessage.integerValue = powerLevels.eventsDefault
            PowerLevelInvite.integerValue = powerLevels.invite
            PowerLevelKick.integerValue = powerLevels.kick
            PowerLevelBan.integerValue = powerLevels.ban
            PowerLevelRedactOther.integerValue = powerLevels.redact
            
            // PowerLevelNotifyAll.integerValue = powerLevels. ?? 50
            // PowerLevelChangeJoinRule.integerValue = powerLevels. ?? 100

            PowerLevelChangeName.integerValue = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.name"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            PowerLevelChangeAvatar.integerValue = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.avatar"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            PowerLevelChangeCanonicalAlias.integerValue = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.canonical_alias"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            PowerLevelChangeHistory.integerValue = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.history_visibility"] as! Int? {
                    return powerLevel
                }
                return 100
            }()
            PowerLevelChangeTopic.integerValue = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.topic"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            PowerLevelChangeWidgets.integerValue = { () -> Int in
                if let powerLevel = powerLevels.events["im.vector.modular.widgets"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            
            let powerChangeLevel = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.power_levels"] as! Int? {
                    return powerLevel
                }
                return 100
            }()
            PowerLevelChangePowerLevels.integerValue = powerChangeLevel
            
            for control in controls {
                control.isEnabled = powerChangeLevel <= powerLevels.powerLevelOfUser(withUserID: MatrixServices.inst.session.myUser.userId)
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        
        if PowerLevelDefault.integerValue != room!.state.powerLevels.usersDefault {
           // room!.
        }
    }
    
}
