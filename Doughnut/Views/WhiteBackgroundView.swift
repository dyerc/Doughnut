//
//  WhiteBackgroundView.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/12/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class WhiteBackgroundView: NSView {
  override func draw(_ dirtyRect: NSRect) {
    // Fill bottom of window with white bg
    let rect = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    NSColor.white.setFill()
    rect.fill()
  }
  
  override var mouseDownCanMoveWindow: Bool {
    return false
  }
}
