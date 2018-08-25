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

class RoomMessageEntry: NSTableCellView {
    @IBOutlet var RoomMessageEntryInboundFrom: NSTextField!
    @IBOutlet var RoomMessageEntryInboundText: NSTextField!
    @IBOutlet var RoomMessageEntryInboundIcon: AvatarImageView!
    @IBOutlet var RoomMessageEntryInboundPadlock: ContextImageView!
    @IBOutlet var RoomMessageEntryInboundTextConstraint: NSLayoutConstraint!
    @IBOutlet var RoomMessageEntryInboundTime: NSTextField!
    
    @IBOutlet var RoomMessageEntryInboundCoalescedText: NSTextField!
    @IBOutlet var RoomMessageEntryInboundCoalescedPadlock: ContextImageView!
    @IBOutlet var RoomMessageEntryInboundCoalescedTextConstraint: NSLayoutConstraint!
    @IBOutlet var RoomMessageEntryInboundCoalescedTime: NSTextField!
    
    @IBOutlet var RoomMessageEntryOutboundFrom: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundText: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundIcon: AvatarImageView!
    @IBOutlet var RoomMessageEntryOutboundPadlock: ContextImageView!
    @IBOutlet var RoomMessageEntryOutboundTextConstraint: NSLayoutConstraint!
    @IBOutlet var RoomMessageEntryOutboundTime: NSTextField!
    
    @IBOutlet var RoomMessageEntryOutboundMediaFrom: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundMediaCollection: NSCollectionView!
    @IBOutlet var RoomMessageEntryOutboundMediaIcon: AvatarImageView!
    @IBOutlet var RoomMessageEntryOutboundMediaPadlock: ContextImageView!
    @IBOutlet var RoomMessageEntryOutboundMediaTime: NSTextField!
    
    @IBOutlet var RoomMessageEntryOutboundCoalescedText: NSTextField!
    @IBOutlet var RoomMessageEntryOutboundCoalescedPadlock: ContextImageView!
    @IBOutlet var RoomMessageEntryOutboundCoalescedTextConstraint: NSLayoutConstraint!
    @IBOutlet var RoomMessageEntryOutboundCoalescedTime: NSTextField!
    
    
    
    @IBOutlet var RoomMessageEntryInlineText: NSTextField!
}
