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

            room.state { state in
                guard let state = state else { fatalError() }

                guard let powerLevels = state.powerLevels else { return }

                self.initialPowerLevelDefault = powerLevels.usersDefault
                self.initialPowerLevelSendMessage = powerLevels.eventsDefault
                self.initialPowerLevelInvite = powerLevels.invite
                self.initialPowerLevelKick = powerLevels.kick
                self.initialPowerLevelBan = powerLevels.ban
                self.initialPowerLevelRedactOther = powerLevels.redact
                // initialPowerLevelNotifyAll = powerLevels. ?? 50
                // initialPowerLevelChangeJoinRule = powerLevels. ?? 100

                self.initialPowerLevelChangeName = { () -> Int in
                    if let powerLevel = powerLevels.events["m.room.name"] as! Int? {
                        return powerLevel
                    }
                    return powerLevels.stateDefault
                }()
                self.initialPowerLevelChangeAvatar = { () -> Int in
                    if let powerLevel = powerLevels.events["m.room.avatar"] as! Int? {
                        return powerLevel
                    }
                    return powerLevels.stateDefault
                }()
                self.initialPowerLevelChangeCanonicalAlias = { () -> Int in
                    if let powerLevel = powerLevels.events["m.room.canonical_alias"] as! Int? {
                        return powerLevel
                    }
                    return powerLevels.stateDefault
                }()
                self.initialPowerLevelChangeHistory = { () -> Int in
                    if let powerLevel = powerLevels.events["m.room.history_visibility"] as! Int? {
                        return powerLevel
                    }
                    return 100
                }()
                self.initialPowerLevelChangeTopic = { () -> Int in
                    if let powerLevel = powerLevels.events["m.room.topic"] as! Int? {
                        return powerLevel
                    }
                    return powerLevels.stateDefault
                }()
                self.initialPowerLevelChangeWidgets = { () -> Int in
                    if let powerLevel = powerLevels.events["im.vector.modular.widgets"] as! Int? {
                        return powerLevel
                    }
                    return powerLevels.stateDefault
                }()
                self.initialPowerLevelChangePowerLevels = { () -> Int in
                    if let powerLevel = powerLevels.events["m.room.power_levels"] as! Int? {
                        return powerLevel
                    }
                    return 100
                }()

                self.PowerLevelDefault.integerValue = self.initialPowerLevelDefault!
                self.PowerLevelSendMessage.integerValue = self.initialPowerLevelSendMessage!
                self.PowerLevelInvite.integerValue = self.initialPowerLevelInvite!
                self.PowerLevelKick.integerValue = self.initialPowerLevelKick!
                self.PowerLevelBan.integerValue = self.initialPowerLevelBan!
                self.PowerLevelRedactOther.integerValue = self.initialPowerLevelRedactOther!
                self.PowerLevelChangeName.integerValue = self.initialPowerLevelChangeName!
                self.PowerLevelChangeAvatar.integerValue = self.initialPowerLevelChangeAvatar!
                self.PowerLevelChangeCanonicalAlias.integerValue = self.initialPowerLevelChangeCanonicalAlias!
                self.PowerLevelChangeHistory.integerValue = self.initialPowerLevelChangeHistory!
                self.PowerLevelChangeTopic.integerValue = self.initialPowerLevelChangeTopic!
                self.PowerLevelChangeWidgets.integerValue = self.initialPowerLevelChangeWidgets!
                self.PowerLevelChangePowerLevels.integerValue = self.initialPowerLevelChangePowerLevels!
                // PowerLevelNotifyAll.integerValue = initialPowerLevelNotifyAll
                // PowerLevelChangeJoinRule.integerValue = initialPowerLevelChangeJoinRule

                for control in controls {
                   // control.isEnabled = initialPowerLevelChangePowerLevels! <= powerLevels.powerLevelOfUser(withUserID: MatrixServices.inst.session.myUser.userId)
                    control.isEnabled = false
                }
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        let group = DispatchGroup()
        
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
