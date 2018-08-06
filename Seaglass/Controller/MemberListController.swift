//
//  MemberListController.swift
//  Seaglass
//
//  Created by Neil Alexander on 06/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class MemberListController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet var MemberSearch: NSSearchField!
    
    public var roomId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if roomId == "" {
            return
        }
        
        let membercount = MatrixServices.inst.session.room(withRoomId: roomId).state.members.count
        MemberSearch.placeholderString = "Search \(membercount) member"
        if membercount != 1 {
            MemberSearch.placeholderString?.append(contentsOf: "s")
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if roomId == "" {
            return 0
        }
        return MatrixServices.inst.session.room(withRoomId: roomId).state.members.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let room = MatrixServices.inst.session.room(withRoomId: roomId)
        let member = room!.state.members[row]
        let powerlevel = room!.state.powerLevels.powerLevelOfUser(withUserID: member.userId)
        
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MemberListEntry"), owner: self) as? MemberListEntry
        
        cell?.MemberName.stringValue = member.displayname ?? member.userId
        cell?.MemberDescription.stringValue = "Power level \(powerlevel)"
        cell?.MemberIcon.image?.setName(NSImage.Name.userGuest)
        cell?.MemberIcon.isHidden = false
        
        return cell
    }
}
