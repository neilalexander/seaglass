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

class UserAvatar: NSImageView {
    
    override var image: NSImage? {
        set {
            self.wantsLayer = true
            if newValue!.isTemplate == false {
                self.canDrawSubviewsIntoLayer = true
              //  self.layer = CALayer()
                self.layer?.contentsGravity = kCAGravityResizeAspectFill
                self.layer?.cornerRadius = (self.frame.height)/2
                self.layer?.masksToBounds = true
                self.alphaValue = 1
            } else {
                self.alphaValue = 0.5
            }
            self.layer?.contents = newValue
            super.image = newValue
        }
        
        get {
            return super.image
        }
    }
    
    func setAvatar(forUserId userId: String) {
        self.image = NSImage(named: NSImage.Name.userGuest)
        if MatrixServices.inst.session.user(withUserId: userId) == nil {
            return
        }
        let user = MatrixServices.inst.session.user(withUserId: userId)!
        if user.avatarUrl.hasPrefix("mxc://") {
            let url = MatrixServices.inst.client.url(ofContent: user.avatarUrl)!
            if url.hasPrefix("http://") || url.hasPrefix("https://") {
                let path = MXMediaManager.cachePathForMedia(withURL: url, andType: nil, inFolder: kMXMediaManagerAvatarThumbnailFolder)
                MXMediaManager.downloadMedia(fromURL: url, andSaveAtFilePath: path, success: {
                    self.image? = MXMediaManager.loadThroughCache(withFilePath: path)
                }) { (error) in
                    self.image = NSImage(named: NSImage.Name.userGuest)
                }
            }
        }
    }
    
    func setAvatar(forRoomId roomId: String) {
        self.image = NSImage(named: NSImage.Name.touchBarNewMessageTemplate)
        if MatrixServices.inst.session.room(withRoomId: roomId) == nil {
            return
        }
        let room = MatrixServices.inst.session.room(withRoomId: roomId)!
        if room.summary.avatar == nil {
            return
        }
        if room.summary.avatar.hasPrefix("mxc://") {
            let url = MatrixServices.inst.client.url(ofContent: room.summary.avatar)!
            if url.hasPrefix("http://") || url.hasPrefix("https://") {
                let path = MXMediaManager.cachePathForMedia(withURL: url, andType: nil, inFolder: kMXMediaManagerAvatarThumbnailFolder)
                MXMediaManager.downloadMedia(fromURL: url, andSaveAtFilePath: path, success: {
                    self.image? = MXMediaManager.loadThroughCache(withFilePath: path)
                }) { (error) in
                    self.image = NSImage(named: NSImage.Name.touchBarNewMessageTemplate)
                }
            }
        }
    }
}
