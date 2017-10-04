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
  
  override var knobThickness: CGFloat {
    return knobWidth
  }
  
  let knobWidth: CGFloat = 4
  let knobHeight: CGFloat = 17
  let knobRadius: CGFloat = 2
  
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
    NSColor.white.setFill()
    NSColor(calibratedRed: 0.6, green: 0.6, blue: 0.6, alpha: 1.0).setStroke()
    
    let rect = NSMakeRect(round(knobRect.origin.x),
                          knobRect.origin.y + 0.5 * (knobRect.height - knobHeight),
                          knobRect.width,
                          knobHeight)
    let path = NSBezierPath(roundedRect: rect, xRadius: knobRadius, yRadius: knobRadius)
    path.fill()
    path.stroke()
  }
  
  override func knobRect(flipped: Bool) -> NSRect {
    let slider = self.controlView as! NSSlider
    let bounds = super.barRect(flipped: flipped)
    let percentage = slider.doubleValue / (slider.maxValue - slider.minValue)
    let pos = min(CGFloat(percentage) * bounds.width, bounds.width - 1);
    let rect = super.knobRect(flipped: flipped)
    let flippedMultiplier = flipped ? CGFloat(-1) : CGFloat(1)
    return NSMakeRect(pos - flippedMultiplier * 0.5 * knobWidth, rect.origin.y, knobWidth, rect.height)
  }
}
