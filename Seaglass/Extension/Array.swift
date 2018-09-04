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

import SwiftMatrixSDK

extension Array where Element == MXEvent {
    mutating func insertByTS(_ element: MXEvent) {
        switch self.count {
        case 0:
            self.insert(element, at: 0)
            return
        case 1:
            if element.ageLocalTs >= self[0].ageLocalTs {
                self.append(element)
            } else {
                self.insert(element, at: 0)
            }
            return
        default:
            if element.ageLocalTs < self.first!.ageLocalTs {
                self.insert(element, at: 0)
                return
            }
            if element.ageLocalTs > self.last!.ageLocalTs {
                self.append(element)
                return
            }
            for n in 0..<self.count-1 {
                let a = self[n]
                let b = self[n+1]
                if a.ageLocalTs >= element.ageLocalTs && element.ageLocalTs <= b.ageLocalTs {
                    self.insert(element, at: n+1)
                    return
                }
            }
            self.append(element)
        }
    }
}
