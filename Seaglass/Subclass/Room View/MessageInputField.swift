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

@IBDesignable class MessageInputField: NSControl, NSTextFieldDelegate {
    @IBOutlet var contentView: NSView?
    @IBOutlet var textField: NSTextField!
    @IBOutlet var delegate: NSObject?
    @IBOutlet var emojiButton: NSButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        var topLevelObjects : NSArray?
        if Bundle.main.loadNibNamed(NSNib.Name("MessageInputField"), owner: self, topLevelObjects: &topLevelObjects) {
            contentView = topLevelObjects!.first(where: { $0 is NSView }) as? NSView
            self.addSubview(contentView!)
            contentView?.frame = self.bounds
            
            textField.focusRingType = .none
            textField.delegate = self
        }
    }
    
    override var intrinsicContentSize: CGSize {
        textField.preferredMaxLayoutWidth = self.frame.width - 34
        return CGSize(width: textField.intrinsicContentSize.width + 34, height: 8 + textField.intrinsicContentSize.height)
    }
    
    @IBAction func emojiButtonClicked(_ sender: NSButton) {
        textField.selectText(self)
        
        let lengthOfInput = NSString(string: textField.stringValue).length
        textField.currentEditor()?.selectedRange = NSMakeRange(lengthOfInput, 0)
        
        NSApplication.shared.orderFrontCharacterPalette(nil)
    }
    
    public override func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField == textField {
            textField.invalidateIntrinsicContentSize()
            self.invalidateIntrinsicContentSize()
            self.superview?.invalidateIntrinsicContentSize()
            if delegate != nil {
                delegate?.controlTextDidChange(obj)
            }
        }
    }
}
