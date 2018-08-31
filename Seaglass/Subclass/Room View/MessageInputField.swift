//
//  MessageInputView.swift
//  Seaglass
//
//  Created by Neil Alexander on 31/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
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
           // self.layoutSubtreeIfNeeded()
            if delegate != nil {
                delegate?.controlTextDidChange(obj)
            }
        }
    }
}
