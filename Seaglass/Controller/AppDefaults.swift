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

import Foundation

final class AppDefaults {
    
    static let shared = AppDefaults()
    
    struct Key {
        static let showMostRecentMessageInSidebar = "showMostRecentMessageInSidebar"
    }
    
    @discardableResult init() {
        let defaults: [String: Any] = [
            Key.showMostRecentMessageInSidebar: true
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
    
    var showMostRecentMessageInSidebar: Bool {
        get {
            return bool(for: Key.showMostRecentMessageInSidebar)
        }
        set {
            setBool(for: Key.showMostRecentMessageInSidebar, newValue)
        }
    }
}

private extension AppDefaults {
    
    func bool(for key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    func setBool(for key: String, _ flag: Bool) {
        UserDefaults.standard.set(flag, forKey: key)
    }

}
