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
import Quartz

class InlineImageView: ContextImageView, QLPreviewItem, QLPreviewPanelDelegate, QLPreviewPanelDataSource {
    var previewItemURL: URL!
    
    var realurl: String?
    
    var maxDimensionWidth: CGFloat = 256
    var maxDimensionHeight: CGFloat = 256
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return previewItemURL.isFileURL ? 1 : 0
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return previewItemURL as QLPreviewItem
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func resetImage() {
        self.image = nil
        if let constraint = self.constraints.first(where: { $0.identifier! == "height" }) {
            constraint.constant = 16
        }
        self.handler = nil
        self.setNeedsDisplay()
    }
    
    func setImage(forMxcUrl: String?, withMimeType: String?, useCached: Bool = true, enableQuickLook: Bool = true) {
        guard let mxcURL = forMxcUrl else { return }
        
        if mxcURL.hasPrefix("mxc://") {
            guard let url = MatrixServices.inst.client.url(ofContentThumbnail: forMxcUrl, toFitViewSize: CGSize(width: 96, height: 96), with: MXThumbnailingMethodScale) else { return }
            guard let realurl = MatrixServices.inst.client.url(ofContent: forMxcUrl) else { return }
            
            if url.hasPrefix("http://") || url.hasPrefix("https://") {
                guard let path = MXMediaManager.cachePathForMedia(withURL: url, andType: withMimeType, inFolder: kMXMediaManagerDefaultCacheFolder) else { return }
      
                if enableQuickLook {
                    self.handler = { (sender, roomId, eventId, userId) in
                        guard let realpath = MXMediaManager.cachePathForMedia(withURL: realurl, andType: withMimeType, inFolder: kMXMediaManagerDefaultCacheFolder) else { return }
                        if !FileManager.default.fileExists(atPath: realpath) || !useCached {
                            MXMediaManager.downloadMedia(fromURL: realurl, andSaveAtFilePath: realpath, success: { [weak self] in
                                self?.previewItemURL = URL(fileURLWithPath: realpath)
                                if self?.previewItemURL.isFileURL ?? false {
                                    QLPreviewPanel.shared().delegate = self
                                    QLPreviewPanel.shared().dataSource = self
                                    QLPreviewPanel.shared().makeKeyAndOrderFront(self)
                                }
                            }, failure: {[weak self] (error) in
                                self?.previewItemURL = URL(fileURLWithPath: path)
                                if self?.previewItemURL.isFileURL ?? false {
                                    QLPreviewPanel.shared().delegate = self
                                    QLPreviewPanel.shared().dataSource = self
                                    QLPreviewPanel.shared().makeKeyAndOrderFront(self)
                                }
                            })
                        } else {
                            self.previewItemURL = URL(fileURLWithPath: realpath)
                            if self.previewItemURL.isFileURL {
                                QLPreviewPanel.shared().delegate = self
                                QLPreviewPanel.shared().dataSource = self
                                QLPreviewPanel.shared().makeKeyAndOrderFront(self)
                            }
                        }
                    } as (_: NSView, _: MXRoom?, _: MXEvent?, _: String?) -> ()
                } else {
                    self.handler = nil
                }
                
                if FileManager.default.fileExists(atPath: path) && useCached {
                    { [weak self] in
                        if let image = MXMediaManager.loadThroughCache(withFilePath: path) {
                            self?.image = image
                            var width = self?.image?.size.width
                            var height = self?.image?.size.height
                            if width! > maxDimensionWidth {
                                let factor = 1 / width! * maxDimensionWidth
                                width = maxDimensionWidth
                                height = height! * factor
                            }
                            if height! > maxDimensionHeight {
                                let factor = 1 / height! * maxDimensionHeight
                                height = maxDimensionHeight
                                width = width! * factor
                            }
                            if let constraint = self?.constraints.first(where: { $0.identifier! == "height" }) {
                                constraint.constant = height!
                            }
                            self?.setNeedsDisplay()
                        }
                    }()
                } else {
                    DispatchQueue.main.async {
                        let previousPath = path
                        MXMediaManager.downloadMedia(fromURL: url, andSaveAtFilePath: path, success: { [weak self] in
                            if let image = MXMediaManager.loadThroughCache(withFilePath: path) {
                                guard previousPath == path else { return }
                                self?.image = image
                                var width = self?.image?.size.width
                                var height = self?.image?.size.height
                                if width! > 256 {
                                    let factor = 1 / width! * 256
                                    width = 256
                                    height = height! * factor
                                }
                                if height! > 256 {
                                    let factor = 1 / height! * 256
                                    height = 256
                                    width = width! * factor
                                }
                                if let constraint = self?.constraints.first(where: { $0.identifier! == "height" }) {
                                    constraint.constant = height!
                                }
                                self?.setNeedsDisplay()
                            }
                        }) { [weak self] (error) in
                            guard previousPath == path else { return }
                            self?.image = NSImage(named: NSImage.Name.invalidDataFreestandingTemplate)
                            self?.sizeToFit()
                        }
                    }
                }
            }
        }
    }
}
