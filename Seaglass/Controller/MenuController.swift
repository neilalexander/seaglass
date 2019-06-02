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

class MenuController: NSMenu {
    
	@IBAction func focusOnRoomSearchField(_ sender: NSMenuItem) {
		sender.target = self

		let mainWindow = NSApplication.shared.mainWindow
		let splitViewController = mainWindow?.contentViewController as? NSSplitViewController
		let mainRoomsViewController = splitViewController?.splitViewItems.first?.viewController as? MainViewRoomsController

		if let searchField = mainRoomsViewController?.RoomSearch {
			searchField.selectText(sender)

			let lengthOfInput = NSString(string: searchField.stringValue).length
			searchField.currentEditor()?.selectedRange = NSMakeRange(lengthOfInput, 0)
		}
	}
    
    @IBAction func inviteButtonClicked(_ sender: NSMenuItem) {
        MatrixServices.inst.mainController?.channelDelegate?.uiRoomStartInvite()
    }
    
    @IBAction func gotoOldestLoaded(_ sender: NSMenuItem) {
        let mainWindow = NSApplication.shared.mainWindow
        let splitViewController = mainWindow?.contentViewController as? NSSplitViewController
        let mainRoomViewController = splitViewController?.splitViewItems.last?.viewController as? MainViewRoomController
        
        mainRoomViewController?.RoomMessageTableView.scrollToBeginningOfDocument(self)
    }
    
    @IBAction func gotoNewest(_ sender: NSMenuItem) {
        let mainWindow = NSApplication.shared.mainWindow
        let splitViewController = mainWindow?.contentViewController as? NSSplitViewController
        let mainRoomViewController = splitViewController?.splitViewItems.last?.viewController as? MainViewRoomController
        
        mainRoomViewController?.RoomMessageTableView.scrollToEndOfDocument(self)
    }	
    
}
