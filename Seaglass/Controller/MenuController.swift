//
//  MenuController.swift
//  Seaglass
//
//  Created by Aaron Raimist on 9/19/18.
//  Copyright © 2018 Neil Alexander. All rights reserved.
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
}
