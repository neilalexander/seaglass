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

import AppKit
import TSMarkdownParser

extension String {
    func toAttributedStringFromMarkdown(justify: NSTextAlignment) -> NSAttributedString{
        if self.count == 0 {
            return NSAttributedString()
        }
        guard let data = data(using: .utf16, allowLossyConversion: true) else { return NSAttributedString() }
        if data.isEmpty {
            return NSAttributedString()
        }
        
        let parser = TSMarkdownParser.standard()
        parser.monospaceAttributes["NSColor"] = NSColor.black
        parser.monospaceAttributes["NSFont"] = NSFont(name: "Menlo", size: NSFont.smallSystemFontSize)
        parser.quoteAttributes[0]["NSColor"] = NSColor.gray
        parser.quoteAttributes[0]["NSFont"] = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        
        let str: NSMutableAttributedString = parser.attributedString(fromMarkdown: self) as! NSMutableAttributedString
        let range = NSRange(location: 0, length: str.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = justify
        
        str.beginEditing()
        str.removeAttribute(.paragraphStyle, range: range)
        str.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        str.endEditing()
        
        return str
    }
    
    func toAttributedStringFromHTML(justify: NSTextAlignment) -> NSAttributedString{
        if self.count == 0 {
            return NSAttributedString()
        }
        guard let data = data(using: .utf16, allowLossyConversion: true) else { return NSAttributedString() }
        if data.isEmpty {
            return NSAttributedString()
        }
        do {
            
            let str: NSMutableAttributedString = try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            let range = NSRange(location: 0, length: str.length)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = justify
            
            str.beginEditing()
            str.removeAttribute(.paragraphStyle, range: range)
            
            str.enumerateAttributes(in: range, options: [], using: { attr, attrRange, _ in
                if let font = attr[.font] as? NSFont {
                    if font.familyName == "Times" {
                        let newFont = NSFontManager.shared.convert(font, toFamily: NSFont.systemFont(ofSize: NSFont.systemFontSize).familyName!)
                        str.addAttribute(.font, value: newFont, range: attrRange)
                    }
                }
            })
            
            str.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            str.endEditing()
            
            return str
        } catch {
            return NSAttributedString()
        }
    }
}
