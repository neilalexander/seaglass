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

extension NSImageView {
    func isVisible(inView: NSView?) -> Bool {
        guard let inView = inView else { return true }
        let viewFrame = inView.convert(self.bounds, from: self)
        if viewFrame.intersects(inView.bounds) {
            return isVisible(inView: inView.superview)
        }
        return false
    }
    
    func isVisible() -> Bool {
        return self.isVisible(inView: self.superview)
    }
    
    func setAvatar(forMxcUrl: String, defaultImageName: NSImage.Name, useCached: Bool = true) {
        if forMxcUrl.hasPrefix("mxc://") {
            let url = MatrixServices.inst.client.url(ofContent: forMxcUrl)!
            if url.hasPrefix("http://") || url.hasPrefix("https://") {
                let path = MXMediaManager.cachePathForMedia(withURL: url, andType: nil, inFolder: kMXMediaManagerAvatarThumbnailFolder)
                if path == nil {
                    self.image? = NSImage.init(named: defaultImageName)!
                    return
                }
                if FileManager.default.fileExists(atPath: path!) && useCached {
                    { [weak self] in
                        if self != nil {
                            let image = MXMediaManager.loadThroughCache(withFilePath: path)
                            if image != nil {
                                self?.image? = image!
                            } else {
                                self?.image? = NSImage.init(named: defaultImageName)!
                            }
                        }
                        }()
                } else {
                    DispatchQueue.main.async {
                        MXMediaManager.downloadMedia(fromURL: url, andSaveAtFilePath: path, success: { [weak self] in
                            if self != nil {
                                // self.wantsLayer = true
                                // self.layer?.contentsGravity = kCAGravityResizeAspectFill
                                // self.layer?.cornerRadius = (self.frame.width)/2
                                // self.layer?.masksToBounds = true
                                // self.canDrawSubviewsIntoLayer = true
                                let image = MXMediaManager.loadThroughCache(withFilePath: path)
                                if image != nil {
                                    self?.image? = image!
                                } else {
                                    self?.image? = NSImage.init(named: defaultImageName)!
                                }
                                // self.wantsLayer = true
                            }
                        }) { [weak self] (error) in
                            print("Error setting avatar from MXC URL \(forMxcUrl)")
                            if self != nil {
                                self?.image? = NSImage.init(named: defaultImageName)!
                            }
                        }
                    }
                }
            } else {
                self.image? = NSImage.init(named: defaultImageName)!
            }
        } else {
            self.image? = NSImage.init(named: defaultImageName)!
        }
    }
    
    func setAvatar(forUserId userId: String, useCached: Bool = true) {
        if MatrixServices.inst.session.user(withUserId: userId) == nil {
            return
        }
        let user = MatrixServices.inst.session.user(withUserId: userId)!
        if user.avatarUrl != nil {
            self.setAvatar(forMxcUrl: user.avatarUrl, defaultImageName: NSImage.Name.touchBarUserTemplate, useCached: useCached)
        }
    }
    
    func setAvatar(forRoomId roomId: String, useCached: Bool = true) {
        if MatrixServices.inst.session.room(withRoomId: roomId) == nil {
            return
        }
        let room = MatrixServices.inst.session.room(withRoomId: roomId)!
        if room.summary.avatar != nil {
            self.setAvatar(forMxcUrl: room.summary.avatar, defaultImageName: NSImage.Name.touchBarNewMessageTemplate, useCached: useCached)
        }
    }
}
