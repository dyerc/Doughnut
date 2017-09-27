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
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    if false {
      NSColor.init(red: 1.0, green: 0.824, blue: 0.180, alpha: 1.0).setFill()
      __NSRectFill(NSRect(x: 0, y: -0, width: 3, height: self.bounds.height))
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
