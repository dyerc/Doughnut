/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 Chris Dyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Cocoa

class PodcastUnplayedCountView: NSView {
  var value = 0 {
    didSet {
      if value < 1 {
        self.isHidden = true
      } else {
        self.isHidden = false
      }
      
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.paragraphSpacing = 0
      paragraphStyle.lineSpacing = 0
    
      attrString = NSMutableAttributedString(string: String(value), attributes: [
        NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 11),
        NSAttributedStringKey.foregroundColor: NSColor.white,
        NSAttributedStringKey.paragraphStyle: paragraphStyle
      ])
    }
  }
  
  // Render in blue on white bg
  var highlightColor = false {
    didSet {
      self.needsDisplay = true
    }
  }
  
  let loadingIndicator = NSProgressIndicator()
  
  var loading: Bool = false {
    didSet {
      loadingIndicator.isHidden = !loading
      
      if loading {
        loadingIndicator.startAnimation(self)
      } else {
        loadingIndicator.stopAnimation(self)
      }
    }
  }
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    
    loadingIndicator.isHidden = true
    loadingIndicator.style = .spinning
    loadingIndicator.isIndeterminate = true
    
    addSubview(loadingIndicator)
  }
  
  override func viewDidMoveToWindow() {
    loadingIndicator.frame = NSRect(x: (frame.width - 16) / 2, y: (frame.height - 16) / 2, width: 16.0, height: 16.0)
  }
  
  var attrString = NSMutableAttributedString(string: "")
  
  override func draw(_ dirtyRect: NSRect) {
    if !loading {
      let bb = attrString.boundingRect(with: CGSize(width: 50, height: 18), options: [])
      
      let X_PAD: CGFloat = 7.0
      let Y_PAD: CGFloat = 2.0
      
      let bgWidth = bb.width + (X_PAD * CGFloat(2))
      let bgHeight = bb.height + (Y_PAD * CGFloat(2))
      let bgMidPoint: CGFloat = bgHeight * 0.5
      let bgRect = NSRect(x: bounds.width - bgWidth, y: bounds.midY - bgMidPoint, width: bgWidth, height: bgHeight)
      
      let bg = NSBezierPath(roundedRect: bgRect, xRadius: 5, yRadius: 5)
      
      if highlightColor {
        let selectedBlue = NSColor(calibratedRed: 0.090, green: 0.433, blue: 0.937, alpha: 1.0)
        selectedBlue.setFill()
      } else {
        NSColor.gray.setFill()
      }
      
      bg.fill()
      
      attrString.draw(with: NSRect(x: bgRect.minX + X_PAD, y: bgRect.minY + 3 + Y_PAD, width: bb.width, height: bb.height), options: [])
    }
  }
}

class PodcastCellView: NSTableCellView {
  @IBOutlet weak var artwork: NSImageView!
  @IBOutlet weak var title: NSTextField!
  @IBOutlet weak var author: NSTextField!
  @IBOutlet weak var episodeCount: NSTextField!
  @IBOutlet weak var podcastUnplayedCount: PodcastUnplayedCountView!
  
  var loading: Bool = false {
    didSet {
      needsDisplay = true
      podcastUnplayedCount.loading = loading
    }
  }
  
  override var backgroundStyle: NSView.BackgroundStyle {
    willSet {
      if newValue == .dark {
        title.textColor = NSColor.white
        author.textColor = NSColor.init(white: 0.9, alpha: 1.0)
        episodeCount.textColor = NSColor.init(white: 0.9, alpha: 1.0)
        podcastUnplayedCount.highlightColor = true
      } else {
        title.textColor = NSColor.labelColor
        author.textColor = NSColor.secondaryLabelColor
        episodeCount.textColor = NSColor.secondaryLabelColor
        podcastUnplayedCount.highlightColor = false
      }
    }
  }
}
