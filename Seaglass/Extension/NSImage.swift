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

extension NSImage {
    func tint(with tintColor: NSColor) -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }
        
        return NSImage(size: size, flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            
            tintColor.set()
            context.clip(to: bounds, mask: cgImage)
            context.fill(bounds)
            
            return true
        }
    }
    
    static func create(withLetterString: String = "?") -> NSImage
    {
        let startImage = #imageLiteral(resourceName: "PlaceholderGradient")
        let letterSize: CGFloat = 72
        
        let imageRect = CGRect(x: 0, y: 0, width: startImage.size.width, height: startImage.size.height)
        let textRect = CGRect(x: startImage.size.width / 2 - letterSize / 2, y: startImage.size.height / 2 - letterSize / 1.5, width: letterSize, height: letterSize * 1.5)
        let textPara = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        textPara.alignment = .center
        
        let textFontAttributes: [NSAttributedStringKey: Any] = [
            .font: NSFont(name: "Arial Rounded MT Bold", size: letterSize)!,
            .paragraphStyle: textPara,
            .foregroundColor: NSColor.white
        ]
        
        let image: NSImage = NSImage(size: startImage.size)
        let representation: NSBitmapImageRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0)!
        
        image.addRepresentation(representation)
        image.lockFocus()
        
        let letter = withLetterString.first { (character) -> Bool in
            return CharacterSet.alphanumerics.contains(String(character).unicodeScalars.first!)
        }
        
        startImage.draw(in: imageRect)
        String(letter ?? "?").uppercased().draw(in: textRect, withAttributes: textFontAttributes)
        
        image.unlockFocus()
        return image
    }
}
