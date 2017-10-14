//
//  EpisodeCellView.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class EpisodeCellView: NSTableCellView {
  @IBOutlet weak var title: NSTextField!
  @IBOutlet weak var summary: NSTextField!
  @IBOutlet weak var date: NSTextField!
  
  var episode: Episode? {
    didSet {
      title.stringValue = episode?.title ?? ""
      summary.stringValue = episode?.description ?? ""
      
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .short
      dateFormatter.timeStyle = .none
      date.stringValue = dateFormatter.string(from: episode?.pubDate ?? Date())
      
      // Needed in order for favourite, played marks etc to be updated
      needsDisplay = true
    }
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    if episode?.favourite ?? false {
      NSColor.init(red: 1.0, green: 0.824, blue: 0.180, alpha: 1.0).setFill()
      __NSRectFill(NSRect(x: 0, y: -0, width: 3, height: self.bounds.height))
    }
    
    if episode?.downloaded ?? false {
      // Draw download corner triangle
      NSColor(calibratedRed: 0.090, green: 0.433, blue: 0.937, alpha: 1.0).setFill()
      let downloadCorner = NSBezierPath()
      let downloadCornerSize: CGFloat = 25.0
      downloadCorner.move(to: NSPoint(x: self.bounds.width, y: self.bounds.height))
      downloadCorner.line(to: NSPoint(x: self.bounds.width, y: self.bounds.height - downloadCornerSize))
      downloadCorner.line(to: NSPoint(x: self.bounds.width - downloadCornerSize, y: self.bounds.height))
      downloadCorner.close()
      downloadCorner.fill()
      
      // Draw download arrow
      NSColor.white.setFill()
      let downloadTriangle = NSBezierPath()
      let arrowY: CGFloat = bounds.height - 3.0
      let arrowX: CGFloat = bounds.width - 6.0
      let arrowTrailLength: CGFloat = 4.0
      let arrowHeadHeight: CGFloat = 5.0
      let arrowHeadOffset: CGFloat = 3.0
      let arrowWidth: CGFloat = 3.0
      downloadTriangle.move(to: NSPoint(x: arrowX, y: arrowY))
      downloadTriangle.line(to: NSPoint(x: arrowX, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX + arrowHeadOffset, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth / 2, y: arrowY - arrowTrailLength - arrowHeadHeight))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth - arrowHeadOffset, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth, y: arrowY))
      downloadTriangle.close()
      downloadTriangle.fill()
    }
    
    drawBottomBorder()
  }
  
  override var backgroundStyle: NSView.BackgroundStyle {
    willSet {
      if newValue == .dark {
        self.title.textColor = NSColor.white
        summary.textColor = NSColor.init(white: 0.9, alpha: 1.0)
        date.textColor = NSColor.init(white: 0.9, alpha: 1.0)
      } else {
        self.title.textColor = NSColor.labelColor
        summary.textColor = NSColor.secondaryLabelColor
        date.textColor = NSColor.secondaryLabelColor
      }
    }
  }
  
  func drawBottomBorder() {
    NSColor.init(white: 0.9, alpha: 1.0).setStroke()
    let bottomBorder = NSBezierPath()
    bottomBorder.move(to: CGPoint(x: 0, y: 0))
    bottomBorder.line(to: CGPoint(x: self.bounds.width, y: 0))
    bottomBorder.close()
    bottomBorder.stroke()
  }
}
