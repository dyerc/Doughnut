//
//  SeekSlider.swift
//  Doughnut
//
//  Created by Chris Dyer on 01/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class SeekSlider: NSSlider {
  override var knobThickness: CGFloat {
    get {
      return 3
    }
  }
  
  var streamedValue: Double = 0 {
    didSet {
      if let cell = cell as? SeekSliderCell {
        cell.streamed = streamedValue
      }
    }
  }
}

class SeekSliderCell: NSSliderCell {
  var streamed: Double = 0
  
  override init() {
    super.init()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func drawBar(inside aRect: NSRect, flipped: Bool) {
    let progressColor = NSColor(calibratedRed: 0.478, green: 0.478, blue: 0.478, alpha: 1.0)
    let baseColor = NSColor(calibratedRed: 0.729, green: 0.729, blue: 0.729, alpha: 1.0)
    
    var rect = aRect
    rect.origin.x += 0.5
    rect.origin.y += 0.5
    rect.size.height = CGFloat(4)
    let barRadius = CGFloat(1)
    
    let value = CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
    let streamedValue = CGFloat((self.streamed - self.minValue) / (self.maxValue - self.minValue))
    
    var progressRect = rect
    progressRect.size.width = CGFloat(value * (self.controlView!.frame.size.width - 8))
    
    var streamedRect = rect
    streamedRect.size.width = CGFloat(streamedValue * (self.controlView!.frame.size.width - 8))
    
    let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
    baseColor.setStroke()
    bg.lineWidth = 1.0
    bg.stroke()
    
    let secondary = NSBezierPath(roundedRect: streamedRect, xRadius: barRadius, yRadius: barRadius)
    baseColor.setFill()
    secondary.fill()
    
    let active = NSBezierPath(roundedRect: progressRect, xRadius: barRadius, yRadius: barRadius)
    progressColor.setFill()
    active.fill()
  }
  
  override func drawKnob(_ knobRect: NSRect) {
    let path = NSBezierPath(roundedRect: knobRect.insetBy(dx: 1.5, dy: 3), xRadius: 2, yRadius: 3)
    NSColor.white.setFill()
    NSColor(calibratedRed: 0.478, green: 0.478, blue: 0.478, alpha: 1.0).setStroke()
    path.stroke()
    path.fill()
  }
}
