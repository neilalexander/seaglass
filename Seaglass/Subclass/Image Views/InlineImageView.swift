//
//  InlineImageView.swift
//  Seaglass
//
//  Created by Neil Alexander on 24/08/2018.
//  Copyright © 2018 Neil Alexander. All rights reserved.
//

import Cocoa
import SwiftMatrixSDK
import Quartz

class InlineImageView: ContextImageView, QLPreviewItem, QLPreviewPanelDelegate, QLPreviewPanelDataSource {
    var previewItemURL: URL!
    
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
    
    func setImage(forMxcUrl: String?, withMimeType: String?, useCached: Bool = true) {
        guard let mxcURL = forMxcUrl else { return }
        
        if mxcURL.hasPrefix("mxc://") {
            guard let url = MatrixServices.inst.client.url(ofContent: forMxcUrl) else { return }
            
            if url.hasPrefix("http://") || url.hasPrefix("https://") {
                guard let path = MXMediaManager.cachePathForMedia(withURL: url, andType: withMimeType, inFolder: kMXMediaManagerDefaultCacheFolder) else { return }
                previewItemURL = URL(fileURLWithPath: path)
                
                self.handler = { (roomId, eventId, userId) in
                    if self.previewItemURL.isFileURL {
                        QLPreviewPanel.shared().delegate = self
                        QLPreviewPanel.shared().dataSource = self
                        QLPreviewPanel.shared().makeKeyAndOrderFront(self)
                    }
                } as (_: String?, _: String?, _: String?) -> ()
                
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
                        MXMediaManager.downloadMedia(fromURL: url, andSaveAtFilePath: path, success: { [weak self] in
                            if let image = MXMediaManager.loadThroughCache(withFilePath: path) {
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
                            self?.image = NSImage(named: NSImage.Name.invalidDataFreestandingTemplate)
                            self?.sizeToFit()
                        }
                    }
                }
            }
        }
    }
}
