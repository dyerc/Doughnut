/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 - 2022 Chris Dyer
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

final class BackgroundView: NSView {

  var backagroundColor = NSColor(named: "ViewBackground")! {
    didSet {
      needsDisplay = true
    }
  }

  var isMovableByViewBackground: Bool?

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    wantsLayer = true
  }

  override var wantsUpdateLayer: Bool {
    return true
  }

  override func updateLayer() {
    layer?.backgroundColor = backagroundColor.cgColor
  }

  override var mouseDownCanMoveWindow: Bool {
    return isMovableByViewBackground ?? super.mouseDownCanMoveWindow
  }

}
