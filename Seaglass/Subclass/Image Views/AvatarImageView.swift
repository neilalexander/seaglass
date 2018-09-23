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

class AvatarImageView: ContextImageView {
    
    var mxcUrl: String?
    var url: String?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        if layer == nil {
            layer = CALayer()
        }
        
        wantsLayer = true
        canDrawSubviewsIntoLayer = true
        
        layer?.masksToBounds = true
        layer?.contentsGravity = kCAGravityResizeAspectFill
        layer?.cornerRadius = (frame.width)/2
    }
    
    override func layout() {
        layer?.cornerRadius = (frame.width)/2
        super.layout()
    }
    
    override var image: NSImage? {
        set {
            layer?.contents = newValue
            super.image = newValue
        }
        get {
            return super.image
        }
    }
    
    func setAvatar(forMxcUrl: String?, defaultImage: NSImage, useCached: Bool = true) {
        guard mxcUrl != forMxcUrl else { return }
        if let cacheUrl = forMxcUrl {
            if useCached && MatrixServices.inst.avatarCache.keys.contains(cacheUrl) {
                if image != MatrixServices.inst.avatarCache[cacheUrl] {
                    image = MatrixServices.inst.avatarCache[cacheUrl]
                    return
                }
            }
        }
        image = defaultImage
        mxcUrl = forMxcUrl
        guard mxcUrl != nil else { return }
        
        if mxcUrl!.hasPrefix("mxc://") {
            url = MatrixServices.inst.client.url(ofContentThumbnail: forMxcUrl, toFitViewSize: CGSize(width: 96, height: 96), with: MXThumbnailingMethodScale)
            guard url != nil else { return }
            
            if url!.hasPrefix("http://") || url!.hasPrefix("https://") {
                guard let path = MXMediaManager.cachePathForMedia(withURL: url, andType: nil, inFolder: kMXMediaManagerAvatarThumbnailFolder) else { return }
                
                if FileManager.default.fileExists(atPath: path) && useCached {
                    { [weak self] in
                        if let image = MXMediaManager.loadThroughCache(withFilePath: path) {
                            self?.image = image
                            self?.layout()
                            if let cacheUrl = forMxcUrl {
                                MatrixServices.inst.avatarCache[cacheUrl] = image
                            }
                        }
                    }()
                } else {
                    DispatchQueue.main.async {
                        let previousPath = path
                        MXMediaManager.downloadMedia(fromURL: self.url!, andSaveAtFilePath: path, success: { [weak self] in
                            if let image = MXMediaManager.loadThroughCache(withFilePath: path) {
                                guard previousPath == path else { return }
                                self?.image = image
                                if let cacheUrl = forMxcUrl {
                                    MatrixServices.inst.avatarCache[cacheUrl] = image
                                }
                                self?.layout()
                            }
                        }) { [weak self] (error) in
                            guard previousPath == path else { return }
                            self?.image = defaultImage
                            self?.layout()
                        }
                    }
                }
            }
        }
    }
    
    func setAvatar(forUserId userId: String, useCached: Bool = true) {
        guard let user = MatrixServices.inst.session.user(withUserId: userId) else {
            setAvatar(forText: "?")
            return
        }
        
        if user.avatarUrl != "" {
            setAvatar(forMxcUrl: user.avatarUrl, defaultImage: NSImage.create(withLetterString: user.displayname ?? "?"), useCached: useCached)
        } else {
            setAvatar(forText: user.displayname)
        }
    }
    
    func setAvatar(forRoomId roomId: String, useCached: Bool = true) {
        guard let room = MatrixServices.inst.session.room(withRoomId: roomId) else {
            setAvatar(forText: "?")
            return
        }
        
        if room.summary.avatar != "" {
            setAvatar(forMxcUrl: room.summary.avatar, defaultImage: NSImage.create(withLetterString: room.summary.displayname ?? "?"), useCached: useCached)
        } else {
            setAvatar(forText: room.summary.displayname)
        }
    }
    
    func setAvatar(forText: String) {
        let letter = forText.first { (character) -> Bool in
            return CharacterSet.alphanumerics.contains(String(character).unicodeScalars.first!)
        }
        
        if MatrixServices.inst.avatarCache.keys.contains(String(letter ?? "?")) {
            image = MatrixServices.inst.avatarCache[String(letter ?? "?")]
        } else {
            image = NSImage.create(withLetterString: forText)
            MatrixServices.inst.avatarCache[String(letter ?? "?")] = image
        }
    }
    
}
