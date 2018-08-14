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

class AboutViewController: NSViewController {
    
    @IBOutlet weak var versionTextField: NSTextField!

    @IBAction func viewSourceCodeButtonPressed(_: NSButton) {
        let sourceURL = NSURL(string: "https://github.com/neilalexander/seaglass")! as URL
        NSWorkspace.shared.open(sourceURL)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let shortHash: String = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_SHORT_HASH") as! String

        versionTextField.stringValue = "Version " + appVersionString + " (" + buildNumber + ") " + shortHash
    }
    
}
