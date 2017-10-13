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
  
  var download: Download? {
    didSet {
      download?.delegate = self
      
      episodeTitle.stringValue = download?.episode.title ?? ""
    }
  }
  
  func downloadProgressed() {
    guard let download = download else { return }
    
    if download.totalBytes > 0 {
      print("Progress \(download.progressedBytes)")
      progressBar.stopAnimation(self)
      progressBar.minValue = 0
      progressBar.maxValue = 1
      progressBar.isIndeterminate = false
      progressBar.doubleValue = download.progressedBytes / download.totalBytes
    } else {
      progressBar.startAnimation(self)
      progressBar.isIndeterminate = true
      progressBar.doubleValue = 0
      progressBar.minValue = 0
      progressBar.maxValue = 0
    }
  }
}
