//
//  UserAvatar.swift
//  Seaglass
//
//  Created by Neil Alexander on 06/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK

class UserAvatar: NSImageView {
    
    override var image: NSImage? {
        set {
            self.wantsLayer = true
            self.canDrawSubviewsIntoLayer = true
            
          //  self.layer = CALayer()
            self.layer?.contentsGravity = kCAGravityResizeAspectFill
            self.layer?.contents = newValue
            self.layer?.cornerRadius = (self.frame.height)/2
            self.layer?.contentsGravity = kCAGravityResizeAspectFill
            self.layer?.masksToBounds = true
            
            super.image = newValue
        }
        
        get {
            return super.image
        }
    }
    
    func setAvatar(forUserId userId: String) {
        self.image?.setName(NSImage.Name.userGuest)
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
                    self.image?.setName(NSImage.Name.userGuest)
                }
            } else {
                self.image?.setName(NSImage.Name.userGuest)
            }
        } else {
            self.image?.setName(NSImage.Name.userGuest)
        }
    }
}
