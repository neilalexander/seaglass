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
    
    var initialPowerLevelDefault: Int?
    var initialPowerLevelSendMessage: Int?
    var initialPowerLevelInvite: Int?
    var initialPowerLevelKick: Int?
    var initialPowerLevelBan: Int?
    var initialPowerLevelRedactOther: Int?
    var initialPowerLevelNotifyAll: Int?
    var initialPowerLevelChangeName: Int?
    var initialPowerLevelChangeAvatar: Int?
    var initialPowerLevelChangeCanonicalAlias: Int?
    var initialPowerLevelChangeHistory: Int?
    var initialPowerLevelChangeJoinRule: Int?
    var initialPowerLevelChangeTopic: Int?
    var initialPowerLevelChangeWidgets: Int?
    var initialPowerLevelChangePowerLevels: Int?
    
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
            
            initialPowerLevelDefault = powerLevels.usersDefault
            initialPowerLevelSendMessage = powerLevels.eventsDefault
            initialPowerLevelInvite = powerLevels.invite
            initialPowerLevelKick = powerLevels.kick
            initialPowerLevelBan = powerLevels.ban
            initialPowerLevelRedactOther = powerLevels.redact
            // initialPowerLevelNotifyAll = powerLevels. ?? 50
            // initialPowerLevelChangeJoinRule = powerLevels. ?? 100

            initialPowerLevelChangeName = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.name"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            initialPowerLevelChangeAvatar = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.avatar"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            initialPowerLevelChangeCanonicalAlias = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.canonical_alias"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            initialPowerLevelChangeHistory = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.history_visibility"] as! Int? {
                    return powerLevel
                }
                return 100
            }()
            initialPowerLevelChangeTopic = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.topic"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            initialPowerLevelChangeWidgets = { () -> Int in
                if let powerLevel = powerLevels.events["im.vector.modular.widgets"] as! Int? {
                    return powerLevel
                }
                return room.state.powerLevels.stateDefault
            }()
            initialPowerLevelChangePowerLevels = { () -> Int in
                if let powerLevel = powerLevels.events["m.room.power_levels"] as! Int? {
                    return powerLevel
                }
                return 100
            }()
            
            PowerLevelDefault.integerValue = initialPowerLevelDefault!
            PowerLevelSendMessage.integerValue = initialPowerLevelSendMessage!
            PowerLevelInvite.integerValue = initialPowerLevelInvite!
            PowerLevelKick.integerValue = initialPowerLevelKick!
            PowerLevelBan.integerValue = initialPowerLevelBan!
            PowerLevelRedactOther.integerValue = initialPowerLevelRedactOther!
            PowerLevelChangeName.integerValue = initialPowerLevelChangeName!
            PowerLevelChangeAvatar.integerValue = initialPowerLevelChangeAvatar!
            PowerLevelChangeCanonicalAlias.integerValue = initialPowerLevelChangeCanonicalAlias!
            PowerLevelChangeHistory.integerValue = initialPowerLevelChangeHistory!
            PowerLevelChangeTopic.integerValue = initialPowerLevelChangeTopic!
            PowerLevelChangeWidgets.integerValue = initialPowerLevelChangeWidgets!
            PowerLevelChangePowerLevels.integerValue = initialPowerLevelChangePowerLevels!
            // PowerLevelNotifyAll.integerValue = initialPowerLevelNotifyAll
            // PowerLevelChangeJoinRule.integerValue = initialPowerLevelChangeJoinRule
            
            for control in controls {
                control.isEnabled = initialPowerLevelChangePowerLevels! <= powerLevels.powerLevelOfUser(withUserID: MatrixServices.inst.session.myUser.userId)
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        let group = DispatchGroup()
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else { return }
        guard let powerLevels = room.state.powerLevels else { return }
        
        if PowerLevelDefault.integerValue != initialPowerLevelDefault! {
            print("Default power level changed")
        }
        
        if PowerLevelSendMessage.integerValue != initialPowerLevelSendMessage! {
            print("Send message power level changed")
        }
        
        if PowerLevelInvite.integerValue != initialPowerLevelInvite! {
            print("Invite power level changed")
        }
        
        if PowerLevelKick.integerValue != initialPowerLevelKick! {
            print("Kick power level changed")
        }
        
        if PowerLevelBan.integerValue != initialPowerLevelBan! {
            print("Ban power level changed")
        }
        
        if PowerLevelRedactOther.integerValue != initialPowerLevelRedactOther! {
            print("Redact other power level changed")
        }
        
        if PowerLevelChangeName.integerValue != initialPowerLevelChangeName! {
            print("Change name level changed")
        }
        
        if PowerLevelChangeAvatar.integerValue != initialPowerLevelChangeAvatar! {
            print("Change avatar power level changed")
        }
        
        if PowerLevelChangeCanonicalAlias.integerValue != initialPowerLevelChangeCanonicalAlias! {
            print("Change canonical alias level changed")
        }
        
        if PowerLevelChangeHistory.integerValue != initialPowerLevelChangeHistory! {
            print("Change history level changed")
        }
        
        if PowerLevelChangeTopic.integerValue != initialPowerLevelChangeTopic! {
            print("Change topic level changed")
        }
        
        if PowerLevelChangeWidgets.integerValue != initialPowerLevelChangeWidgets! {
            print("Change widgets level changed")
        }
        
        if PowerLevelChangePowerLevels.integerValue != initialPowerLevelChangePowerLevels! {
            print("Change power level power level changed")
        }
        
        group.notify(queue: .main, execute: {
            sender.window?.contentViewController?.dismiss(sender)
        })
    }
    
}
