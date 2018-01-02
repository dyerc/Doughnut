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
