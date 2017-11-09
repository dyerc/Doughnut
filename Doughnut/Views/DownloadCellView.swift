//
//  DownloadCellView.swift
//  Doughnut
//
//  Created by Chris Dyer on 11/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class DownloadCellView: NSTableCellView, DownloadProgressDelegate {
  @IBOutlet weak var episodeTitle: NSTextField!
  @IBOutlet weak var progressBar: NSProgressIndicator!
  @IBOutlet weak var progressText: NSTextField!
  
  let byteFormatter = ByteCountFormatter()
  
  var download: DownloadTask? {
    didSet {
      download?.progressDelegate = self
      
      byteFormatter.allowedUnits = .useMB
      byteFormatter.countStyle = .file
      
      episodeTitle.stringValue = download?.episode.title ?? ""
    }
  }
  
  func download(progressed download: DownloadTask) {
    if download.totalBytes > 0 {
      progressBar.stopAnimation(self)
      progressBar.minValue = 0
      progressBar.maxValue = 1
      progressBar.isIndeterminate = false
      progressBar.doubleValue = download.progressedBytes / download.totalBytes

      progressText.stringValue = "\(byteFormatter.string(fromByteCount: Int64(download.progressedBytes))) of \(byteFormatter.string(fromByteCount: Int64(download.totalBytes)))"
    } else {
      progressBar.startAnimation(self)
      progressBar.isIndeterminate = true
      progressBar.doubleValue = 0
      progressBar.minValue = 0
      progressBar.maxValue = 0
      
      progressText.stringValue = "Unknown"
    }
  }
}
