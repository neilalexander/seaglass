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

// Based on: https://gist.github.com/entotsu/ddc136832a87a0fd2f9a0a6d4cf754ea
// https://github.com/DouglasHeriot/AutoGrowingNSTextField

class AutoGrowingTextField: NSTextField {

	let bottomSpace: CGFloat = 2
	// magic number! (the field editor TextView is offset within the NSTextField. It’s easy to get the space above (it’s origin), but it’s difficult to get the default spacing for the bottom, as we may be changing the height

	var heightLimit: CGFloat?
	var lastSize: NSSize?
	var isEditing = false

	override func textDidBeginEditing(_ notification: Notification) {
		super.textDidBeginEditing(notification)
		isEditing = true
	}

	override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)
		isEditing = false
	}

	override func textDidChange(_ notification: Notification) {
		super.textDidChange(notification)
		self.invalidateIntrinsicContentSize()
	}

	override var intrinsicContentSize: NSSize {
		let minSize: NSSize = super.intrinsicContentSize

		// Only update the size if we’re editing the text, or if we’ve not set it yet
		// If we try and update it while another text field is selected, it may shrink back down to only the size of one line (for some reason?)
		if isEditing || lastSize == nil {
			guard let
				// If we’re being edited, get the shared NSTextView field editor, so we can get more info
				textView = self.window?.fieldEditor(false, for: self) as? NSTextView,
				let container = textView.textContainer,
				let newHeight = container.layoutManager?.usedRect(for: container).height
				else {
					return lastSize ?? minSize
			}
			var newSize = super.intrinsicContentSize
			newSize.height = newHeight + bottomSpace

			if let
				heightLimit = heightLimit,
				let lastSize = lastSize, newSize.height > heightLimit {
				newSize = lastSize
			}

			lastSize = newSize
			return newSize
		}
		else {
			return lastSize ?? minSize
		}
	}
}
