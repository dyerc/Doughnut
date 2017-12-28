//
//  ActivityIndicator.swift
//  Doughnut
//
//  Created by Chris Dyer on 28/12/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class ActivityIndicator: NSView {
  let dotSize: CGFloat = 7.0
  let dotSpacing: CGFloat = 5.0
  let dotCount = 3
  
  override func viewDidMoveToWindow() {
    wantsLayer = true
    
    let replLayer = CAReplicatorLayer()
    replLayer.frame = bounds
    
    let dotsX = (bounds.width - (dotSize * 3) - (dotSize * 2)) / 2
    
    let dot = CALayer()
    dot.frame = CGRect(x: dotsX, y: (bounds.height - dotSize) / 2, width: dotSize, height: dotSize)
    dot.backgroundColor = NSColor.darkGray.cgColor
    dot.cornerRadius = dotSize / 2
    
    replLayer.addSublayer(dot)
    replLayer.instanceCount = dotCount
    replLayer.instanceTransform = CATransform3DMakeTranslation(dotSize + dotSpacing, 0, 0)
    
    let animation = CAKeyframeAnimation()
    animation.keyPath = #keyPath(CALayer.opacity)
    animation.values = [0.0, 1.0, 0.0]
    animation.duration = 1.2
    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    animation.repeatCount = .infinity
    dot.add(animation, forKey: nil)
    
    replLayer.instanceDelay = 0.2
    
    layer?.frame = self.frame
    layer?.addSublayer(replLayer)
  }
}
