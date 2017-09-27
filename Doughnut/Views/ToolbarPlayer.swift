//
//  ToolbarPlayer.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class ToolbarPlayer: NSView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    
    let label = NSTextField(frame: NSRect(x: 0, y: 10, width: 40, height: 20))
    label.stringValue = "Test"
    
    self.addSubview(label)
  }
  
  required init?(coder decoder: NSCoder) {
    fatalError("init(frame:) has not been implemented")
  }
}
