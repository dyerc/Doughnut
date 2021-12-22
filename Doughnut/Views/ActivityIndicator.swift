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

class ActivityIndicator: NSView {
  let dotSize: CGFloat = 6.0
  let dotSpacing: CGFloat = 3.0
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
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animation.repeatCount = .infinity
    dot.add(animation, forKey: nil)

    replLayer.instanceDelay = 0.2

    layer?.frame = self.frame
    layer?.addSublayer(replLayer)
  }
}
