//
//  TaskManagerView.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/12/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class TaskManagerView: NSView {
  override func viewDidMoveToWindow() {
    self.wantsLayer = true
    
    if let layer = self.layer {
      layer.frame = self.frame
      
      let loadingSize: CGFloat = 26.0
      
      let object = CALayer()
      object.cornerRadius = 13
      object.backgroundColor = NSColor.red.cgColor
      object.frame = NSRect(x: (layer.frame.width - loadingSize) / 2.0, y: (layer.frame.height - loadingSize) / 2.0, width: loadingSize, height: loadingSize)
      
      layer.addSublayer(object)
    }
  }
}
