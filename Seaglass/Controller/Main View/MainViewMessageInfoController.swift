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
import SwiftMatrixSDK

class MainViewMessageInfoController: NSViewController {
    
    @IBOutlet var EventSourceView: NSTextView!
    @IBOutlet weak var EventTimestamp: NSTextField!
    
    var event: MXEvent?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard event != nil else { return }
        
        let eventTime = Date(timeIntervalSince1970: TimeInterval(event!.originServerTs / 1000))
        let eventTimeFormatter = DateFormatter()
        eventTimeFormatter.timeZone = TimeZone.current
        eventTimeFormatter.timeStyle = .long
        eventTimeFormatter.dateStyle = .long
        
        EventTimestamp.stringValue = eventTimeFormatter.string(from: eventTime)
        do {
            let str = NSString(data: try JSONSerialization.data(withJSONObject: event!.jsonDictionary() as Any, options: JSONSerialization.WritingOptions.prettyPrinted), encoding: String.Encoding.utf8.rawValue)! as String
            EventSourceView.string = str.replacingOccurrences(of: "\\/", with: "/")
        } catch {
            EventSourceView.string = "Exception caught"
        }
    }
    
}
