//
//  RoomMessageEntry.swift
//  Seaglass
//
//  Created by Neil Alexander on 06/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa

class RoomMessageEntry: NSTableCellView {
    @IBOutlet var RoomMessageEntryInboundFrom: NSTextField!
    @IBOutlet var RoomMessageEntryInboundText: NSTextField!
    @IBOutlet var RoomMessageEntryInboundIcon: UserAvatar!
    
    @IBOutlet var RoomMessageEntryOutboundFrom: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundText: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundIcon: UserAvatar!
    
    @IBOutlet var RoomMessageEntryInboundCoalescedText: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundCoalescedText: NSTextField!
    
    @IBOutlet var RoomMessageEntryInlineText: NSTextField!
}
