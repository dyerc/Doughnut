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

class EpisodeCellView: NSTableCellView {
  @IBOutlet weak var title: NSTextField!
  @IBOutlet weak var summary: NSTextField!
  @IBOutlet weak var date: NSTextField!
  @IBOutlet weak var dateOriginConstraint: NSLayoutConstraint!
  @IBOutlet weak var duration: NSTextField!

  let playedIndicatorSize: CGFloat = 10

  var episode: Episode? {
    didSet {
      title.stringValue = episode?.title ?? ""
      summary.stringValue = episode?.plainDescription ?? ""

      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .short
      dateFormatter.timeStyle = .none
      date.stringValue = dateFormatter.string(from: episode?.pubDate ?? Date())

      if (episode?.played ?? true) == false {
        dateOriginConstraint.constant = (12 + playedIndicatorSize + 6)
      } else {
        dateOriginConstraint.constant = 12
      }

      if (episode?.duration ?? 0) > 0 {
        duration.stringValue = Utils.formatDuration((episode?.duration ?? 0) - (episode?.playPosition ?? 0))
      } else {
        duration.stringValue = ""
      }

      // Needed in order for favourite, played marks etc to be updated
      needsDisplay = true
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    guard let episode = episode else { return }

    let selected = backgroundStyle == .dark
    let selectedBlue = NSColor(calibratedRed: 0.090, green: 0.433, blue: 0.937, alpha: 1.0)
    var selectedColor = selectedBlue
    if selected {
      selectedColor = NSColor.white
    }

    if episode.favourite {
      NSColor.init(red: 1.0, green: 0.824, blue: 0.180, alpha: 1.0).setFill()
      __NSRectFill(NSRect(x: 0, y: -0, width: 3, height: self.bounds.height))
    }

    if episode.downloaded {
      // Draw download corner triangle
      selectedColor.setFill()
      let downloadCorner = NSBezierPath()
      let downloadCornerSize: CGFloat = 25.0
      downloadCorner.move(to: NSPoint(x: self.bounds.width, y: self.bounds.height))
      downloadCorner.line(to: NSPoint(x: self.bounds.width, y: self.bounds.height - downloadCornerSize))
      downloadCorner.line(to: NSPoint(x: self.bounds.width - downloadCornerSize, y: self.bounds.height))
      downloadCorner.close()
      downloadCorner.fill()

      // Draw download arrow
      if selected {
        selectedBlue.setFill()
      } else {
        NSColor.white.setFill()
      }
      let downloadTriangle = NSBezierPath()
      let arrowY: CGFloat = bounds.height - 3.0
      let arrowX: CGFloat = bounds.width - 6.0
      let arrowTrailLength: CGFloat = 4.0
      let arrowHeadHeight: CGFloat = 5.0
      let arrowHeadOffset: CGFloat = 3.0
      let arrowWidth: CGFloat = 3.0
      downloadTriangle.move(to: NSPoint(x: arrowX, y: arrowY))
      downloadTriangle.line(to: NSPoint(x: arrowX, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX + arrowHeadOffset, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth / 2, y: arrowY - arrowTrailLength - arrowHeadHeight))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth - arrowHeadOffset, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth, y: arrowY - arrowTrailLength))
      downloadTriangle.line(to: NSPoint(x: arrowX - arrowWidth, y: arrowY))
      downloadTriangle.close()
      downloadTriangle.fill()
    }

    if !episode.played {
      let playedIndicatorRect = NSRect(x: 12, y: 7, width: playedIndicatorSize, height: playedIndicatorSize)

      let playedBg = NSBezierPath(ovalIn: playedIndicatorRect)
      selectedColor.setStroke()
      playedBg.stroke()

      if episode.playPosition > 0 && episode.duration > 0 {
        let playedSlice = NSBezierPath()
        let center = CGPoint(x: playedIndicatorRect.midX, y: playedIndicatorRect.midY)
        let playedPercent = Double(episode.playPosition) / Double(episode.duration)
        let endAngle = CGFloat(360 * playedPercent)
        playedSlice.move(to: center)
        playedSlice.line(to: CGPoint(x: center.x, y: playedIndicatorRect.maxY))
        playedSlice.appendArc(withCenter: center, radius: playedIndicatorRect.size.width / 2, startAngle: 90, endAngle: 90 - endAngle)
        playedSlice.close()

        if backgroundStyle == .dark {
          selectedColor.setFill()
        } else {
          selectedBlue.setFill()
        }
        playedSlice.fill()
      } else {
        selectedColor.setFill()
        playedBg.fill()
      }
    }

    drawBottomBorder()
  }

  override var backgroundStyle: NSView.BackgroundStyle {
    willSet {
      if newValue == .dark {
        self.title.textColor = NSColor.white
        summary.textColor = NSColor.init(white: 0.9, alpha: 1.0)
        date.textColor = NSColor.init(white: 0.9, alpha: 1.0)
        duration.textColor = NSColor.init(white: 0.9, alpha: 1.0)
      } else {
        self.title.textColor = NSColor.labelColor
        summary.textColor = NSColor.secondaryLabelColor
        date.textColor = NSColor.secondaryLabelColor
        duration.textColor = NSColor.secondaryLabelColor
      }

      needsDisplay = true
    }
  }

  func drawBottomBorder() {
    NSColor.init(white: 0.9, alpha: 1.0).setStroke()
    let bottomBorder = NSBezierPath()
    bottomBorder.move(to: CGPoint(x: 0, y: 0))
    bottomBorder.line(to: CGPoint(x: self.bounds.width, y: 0))
    bottomBorder.close()
    bottomBorder.stroke()
  }
}
