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

class PodcastCellView: NSTableCellView {
  @IBOutlet weak var artwork: NSImageView!
  @IBOutlet weak var title: NSTextField!
  @IBOutlet weak var author: NSTextField!
  @IBOutlet weak var episodeCount: NSTextField!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  
  override var backgroundStyle: NSView.BackgroundStyle {
    willSet {
      if newValue == .dark {
        title.textColor = NSColor.white
        author.textColor = NSColor.init(white: 0.9, alpha: 1.0)
        episodeCount.textColor = NSColor.init(white: 0.9, alpha: 1.0)
      } else {
        title.textColor = NSColor.labelColor
        author.textColor = NSColor.secondaryLabelColor
        episodeCount.textColor = NSColor.secondaryLabelColor
      }
    }
  }
}
