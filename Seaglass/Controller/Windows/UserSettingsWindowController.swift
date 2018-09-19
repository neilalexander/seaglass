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

class UserSettingsWindowController: NSWindowController, NSToolbarDelegate {

    @IBOutlet var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let window = self.window {
            if toolbar.items.count == 0 {
                toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier.flexibleSpace, at: 0)
                toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier.init("SeaglassPreferences"), at: 1)
                toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier.flexibleSpace, at: 2)
            }
            
            window.toolbar = toolbar
        }
    }

    @IBAction func didChangeTabs(_ sender: NSSegmentedControl) {
        if let controller = self.window!.contentViewController as? UserSettingsTabViewController {
            controller.tabView.selectTabViewItem(at: sender.selectedSegment)
        }
    }
}
