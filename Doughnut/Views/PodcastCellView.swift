//
//  PodcastRowView.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class PodcastCellView: NSTableCellView {
  @IBOutlet weak var artwork: NSImageView!
  @IBOutlet weak var title: NSTextField!
  @IBOutlet weak var author: NSTextField!
  @IBOutlet weak var episodeCount: NSTextField!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  
  override var backgroundStyle: NSView.BackgroundStyle {
    willSet {
      if newValue == .dark {
        title.textColor = NSColor.white
        author.textColor = NSColor.init(white: 0.9, alpha: 1.0)
        episodeCount.textColor = NSColor.init(white: 0.9, alpha: 1.0)
      } else {
        title.textColor = NSColor.labelColor
        author.textColor = NSColor.secondaryLabelColor
        episodeCount.textColor = NSColor.secondaryLabelColor
      }
    }
  }
}
