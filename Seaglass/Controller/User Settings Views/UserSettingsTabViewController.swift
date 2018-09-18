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

class UserSettingsTabViewController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabView.tabViewType = .noTabsNoBorder
        self.selectedTabViewItemIndex = 0
    }
    
    override func viewWillAppear() {
        if let item = self.tabView.selectedTabViewItem {
            resizeWindowToFit(tabViewItem: item)
        }
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if let item = tabViewItem {
            resizeWindowToFit(tabViewItem: item)
        }
    }

    private func resizeWindowToFit(tabViewItem: NSTabViewItem?) {
        guard let window = view.window else { return }
        
        if let controller = tabViewItem?.viewController as? UserSettingsTabController, let size = controller.resizeToSize {
            let rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
            let frame = window.frameRect(forContentRect: rect)
            let toolbar = window.frame.size.height - frame.size.height
            let origin = NSPoint(x: window.frame.origin.x, y: window.frame.origin.y + toolbar)
            
            window.setFrame(NSRect(origin: origin, size: frame.size), display: false, animate: true)
        }
    }
    
}
