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

extension String {
  func leftPadding(toLength: Int, withPad character: Character) -> String {
    let newLength = self.count
    if newLength < toLength {
      return String(repeatElement(character, count: toLength - newLength)) + self
    } else {
      return String(dropFirst(newLength - toLength))
    }
  }
}

class PlayerView: NSView, PlayerDelegate {
  let width = 425
  var baseline: CGFloat {
    return frame.size.height / 2 - 13
  }

  var loadingIdc: NSProgressIndicator!
  var artworkImg: NSImageView!
  var reverseBtn: NSButton!
  var playBtn: NSButton!
  var forwardBtn: NSButton!
  var playedDurationLbl: NSTextField!
  var seekSlider: SeekSlider!
  var playedRemainingLbl: NSTextField!

  let playIcon = NSImage(imageLiteralResourceName: "PlayIcon")
  let pauseIcon = NSImage(imageLiteralResourceName: "PauseIcon")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    Player.global.delegate = self
  }

  required init?(coder decoder: NSCoder) {
    loadingIdc = NSProgressIndicator(frame: .zero)
    artworkImg = NSImageView(frame: .zero)

    reverseBtn = NSButton.init(frame: .zero)
    playBtn = NSButton.init(frame: .zero)
    forwardBtn = NSButton.init(frame: .zero)

    playedDurationLbl = NSTextField(frame: .zero)
    seekSlider = SeekSlider(frame: .zero)
    playedRemainingLbl = NSTextField(frame: .zero)

    super.init(coder: decoder)
    Player.global.delegate = self

    loadingIdc.isHidden = true
    loadingIdc.minValue = 0
    loadingIdc.maxValue = 0
    loadingIdc.usesThreadedAnimation = true
    loadingIdc.isIndeterminate = true
    loadingIdc.style = .spinning
    loadingIdc.controlSize = .small
    addSubview(loadingIdc)

    artworkImg.isHidden = false
    artworkImg.imageFrameStyle = .none
    artworkImg.image = NSImage(imageLiteralResourceName: "PlaceholderIcon")
    addSubview(artworkImg)

    reverseBtn.stringValue = ""
    reverseBtn.bezelStyle = .texturedRounded
    reverseBtn.image = NSImage(imageLiteralResourceName: "ReverseIcon")
    reverseBtn.contentTintColor = .controlTextColor
    reverseBtn.action = #selector(skipBack)
    reverseBtn.target = self
    addSubview(reverseBtn)

    playBtn.stringValue = ""
    playBtn.bezelStyle = .texturedRounded
    playBtn.setButtonType(.toggle)
    playBtn.image = playIcon
    playBtn.contentTintColor = .controlTextColor
    playBtn.alternateImage = pauseIcon
    playBtn.action = #selector(playPause)
    playBtn.target = self
    playBtn.imagePosition = .imageOnly
    addSubview(playBtn)

    forwardBtn.stringValue = ""
    forwardBtn.bezelStyle = .texturedRounded
    forwardBtn.image = NSImage(imageLiteralResourceName: "ForwardIcon")
    forwardBtn.contentTintColor = .controlTextColor
    forwardBtn.action = #selector(skipAhead)
    forwardBtn.target = self
    addSubview(forwardBtn)

    playedDurationLbl.stringValue = "-:--:--"
    playedDurationLbl.isBezeled = false
    playedDurationLbl.drawsBackground = false
    playedDurationLbl.isSelectable = false
    playedDurationLbl.alignment = .right
    playedDurationLbl.font = NSFont.systemFont(ofSize: 10)
    playedDurationLbl.isEditable = false
    addSubview(playedDurationLbl)

    seekSlider.minValue = 0
    seekSlider.maxValue = 1
    seekSlider.doubleValue = 0
    seekSlider.streamedValue = 0.1
    seekSlider.cell = SeekSliderCell()
    seekSlider.target = self
    seekSlider.action = #selector(seek)
    addSubview(seekSlider)

    playedRemainingLbl.stringValue = "-:--:--"
    playedRemainingLbl.isBezeled = false
    playedRemainingLbl.drawsBackground = false
    playedRemainingLbl.isSelectable = false
    playedRemainingLbl.font = NSFont.systemFont(ofSize: 10)
    playedRemainingLbl.isEditable = false
    addSubview(playedRemainingLbl)

    wantsLayer = true
    updateBackgroundColor()

    var cornerRadius: CGFloat = 4
    if #available(macOS 11.0, *) {
      cornerRadius = 6
    }
    layer?.cornerRadius = cornerRadius
  }

  override func layout() {
    resizeSubviews(withOldSize: .zero)
  }

  override func resizeSubviews(withOldSize oldSize: NSSize) {
    loadingIdc.frame = NSRect(x: 25, y: baseline + 5, width: 16, height: 16)
    artworkImg.frame = NSRect(x: 25, y: baseline + 3, width: 20, height: 20)

    reverseBtn.frame = NSRect(x: PlayerView.controlX(artworkImg) + 6, y: baseline, width: 28, height: 26)
    playBtn.frame = NSRect(x: PlayerView.controlX(reverseBtn) + 1, y: baseline, width: 28, height: 26)
    forwardBtn.frame = NSRect(x: PlayerView.controlX(playBtn) + 1, y: baseline, width: 28, height: 26)

    playedDurationLbl.frame = NSRect(x: PlayerView.controlX(forwardBtn) + 2, y: baseline + 6, width: 50, height: 14)
    seekSlider.frame = NSRect(x: PlayerView.controlX(playedDurationLbl) + 4, y: baseline + 4, width: 200, height: 18)
    playedRemainingLbl.frame = NSRect(x: PlayerView.controlX(seekSlider) + 4, y: baseline + 6, width: 50, height: 14)
  }

  override func viewDidChangeEffectiveAppearance() {
    updateBackgroundColor()
  }

  private func updateBackgroundColor() {
    let backgroundColor = NSApp.effectiveAppearance.isDarkMode ? NSColor.white.withAlphaComponent(0.04)
                                                               : NSColor.black.withAlphaComponent(0.04)
    layer?.backgroundColor = backgroundColor.cgColor
  }

  func formatTime(total: Int) -> String {
    let hrs = Int(floor(Double(total / 3600)))
    let mins = Int(floor(Double((total % 3600) / 60)))
    let secs = Int(total % 60)

    return String(hrs) + ":" + String(mins).leftPadding(toLength: 2, withPad: "0") + ":" + String(secs).leftPadding(toLength: 2, withPad: "0")
  }

  func update(forEpisode episode: Episode?) {
    artworkImg.image = episode?.podcast?.image

    if let image = episode?.artwork, image.isValid {
      artworkImg.image = image
    }
  }

  func updatePlayback() {
    let player = Player.global

    let loadStatus = player.loadStatus
    if loadStatus == .loading {
      loadingIdc.isHidden = false
      loadingIdc.startAnimation(nil)
      artworkImg.isHidden = true
    } else {
      loadingIdc.isHidden = true
      loadingIdc.stopAnimation(nil)
      artworkImg.isHidden = false
    }

    if player.isPlaying {
      playBtn.state = .on
    } else {
      playBtn.state = .off
    }

    let duration = player.duration
    let position = player.position

    playedDurationLbl.stringValue = formatTime(total: Int(position))
    playedRemainingLbl.stringValue = formatTime(total: Int(duration - position))

    seekSlider.minValue = 0
    seekSlider.maxValue = duration
    seekSlider.doubleValue = position
    seekSlider.streamedValue = player.buffered
  }

  // MARK: - Actions

  @objc func seek(_ sender: Any) {
    let event = NSApplication.shared.currentEvent
    // Only react to dragging so that we don't skip back after slider release
    if event?.type == .leftMouseDragged {
      Player.global.seek(seconds: seekSlider.doubleValue)
    }

    if event?.type == .leftMouseUp {
      // Handle a single click
    }
  }

  @objc func playPause(_ sender: Any) {
    let player = Player.global

    if playBtn.state == .on {
      if player.canPlay {
        Player.global.play()
      } else {
        playBtn.state = .off
      }
    } else {
      player.pause()
    }
  }

  @objc func skipAhead(_ sender: Any) {
    let player = Player.global
    player.skipAhead()
  }

  @objc func skipBack(_ sender: Any) {
    let player = Player.global
    player.skipBack()
  }

  static private func controlX(_ view: NSView) -> CGFloat {
    return view.frame.origin.x + view.frame.size.width
  }
}
