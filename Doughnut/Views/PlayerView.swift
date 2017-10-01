//
//  PlayerView.swift
//  Doughnut
//
//  Created by Chris Dyer on 01/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

extension String {
  func leftPadding(toLength: Int, withPad character: Character) -> String {
    let newLength = self.characters.count
    if newLength < toLength {
      return String(repeatElement(character, count: toLength - newLength)) + self
    } else {
      return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
    }
  }
}

class PlayerView: NSView {
  let width = 420
  let baseline: CGFloat = 6
  
  var loadingIdc: NSProgressIndicator!
  var artworkImg: NSImageView!
  var reverseBtn: NSButton!
  var playBtn: NSButton!
  var forwardBtn: NSButton!
  var playedDurationLbl: NSTextField!
  var seekSlider: SeekSlider!
  var playedRemainingLbl: NSTextField!
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }
  
  required init?(coder decoder: NSCoder) {
    loadingIdc = NSProgressIndicator(frame: NSRect(x: 25, y: baseline + 5, width: 16, height: 16))
    artworkImg = NSImageView(frame: NSRect(x: 25, y: baseline + 3, width: 20, height: 20))
    
    reverseBtn = NSButton.init(frame: NSRect(x: PlayerView.controlX(artworkImg) + 6, y: baseline, width: 28, height: 25))
    playBtn = NSButton.init(frame: NSRect(x: PlayerView.controlX(reverseBtn) + 1, y: baseline, width: 28, height: 25))
    forwardBtn = NSButton.init(frame: NSRect(x: PlayerView.controlX(playBtn) + 1, y: baseline, width: 28, height: 25))
    
    playedDurationLbl = NSTextField(frame: NSRect(x: PlayerView.controlX(forwardBtn) + 2, y: baseline + 6, width: 50, height: 14))
    seekSlider = SeekSlider(frame: NSRect(x: PlayerView.controlX(playedDurationLbl) + 4, y: baseline + 4, width: 200, height: 18))
    playedRemainingLbl = NSTextField(frame: NSRect(x: PlayerView.controlX(seekSlider) + 4, y: baseline + 6, width: 50, height: 14))
    
    super.init(coder: decoder)
    
    loadingIdc.isHidden = true
    loadingIdc.minValue = 0
    loadingIdc.maxValue = 0
    loadingIdc.usesThreadedAnimation = true
    loadingIdc.isIndeterminate = true
    loadingIdc.style = .spinning
    addSubview(loadingIdc)
    
    artworkImg.isHidden = false
    artworkImg.imageFrameStyle = .none
    artworkImg.image = NSImage(imageLiteralResourceName: "PlaceholderIcon")
    addSubview(artworkImg)
    
    reverseBtn.stringValue = ""
    reverseBtn.bezelStyle = .texturedRounded
    reverseBtn.image = NSImage(imageLiteralResourceName: "ReverseIcon")
    addSubview(reverseBtn)
    
    playBtn.stringValue = ""
    playBtn.bezelStyle = .texturedRounded
    playBtn.image = NSImage(imageLiteralResourceName: "PlayIcon")
    addSubview(playBtn)
    
    forwardBtn.stringValue = ""
    forwardBtn.bezelStyle = .texturedRounded
    forwardBtn.image = NSImage(imageLiteralResourceName: "ForwardIcon")
    addSubview(forwardBtn)
    
    playedDurationLbl.stringValue = "0:54:05"
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
    
    playedRemainingLbl.stringValue = "0:54:05"
    playedRemainingLbl.isBezeled = false
    playedRemainingLbl.drawsBackground = false
    playedRemainingLbl.isSelectable = false
    playedRemainingLbl.font = NSFont.systemFont(ofSize: 10)
    playedRemainingLbl.isEditable = false
    addSubview(playedRemainingLbl)
    
    NotificationCenter.default.addObserver(self, selector: #selector(updateState), name: Player.Events.StatusChange.notification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(updateTimeState), name: Player.Events.TimeChange.notification, object: nil)
  }
  
  override func draw(_ dirtyRect: NSRect) {
    let bgGradient = NSGradient(starting: NSColor(calibratedRed: 0.945, green: 0.945, blue: 0.945, alpha: 1.0), ending: NSColor(calibratedRed: 0.894, green: 0.894, blue: 0.894, alpha: 1.0))
    bgGradient?.draw(in: self.bounds, angle: 270)
    
    NSColor(calibratedRed: 0.784, green: 0.784, blue: 0.784, alpha: 1.0).setStroke()
    
    let leftBorder = NSBezierPath()
    leftBorder.move(to: NSPoint(x: 0.5, y: 0))
    leftBorder.line(to: NSPoint(x: 0.5, y: self.bounds.size.height))
    leftBorder.stroke()
    
    let rightBorder = NSBezierPath()
    rightBorder.move(to: NSPoint(x: self.bounds.size.width - 0.5, y: 0))
    rightBorder.line(to: NSPoint(x: self.bounds.size.width - 0.5, y: self.bounds.size.height))
    rightBorder.stroke()
    
    super.draw(dirtyRect)
  }
  
  func formatTime(total: Int) -> String {
    let hrs = Int(floor(Double(total / 3600)))
    let mins = Int(floor(Double((total % 3600) / 60)))
    let secs = Int(total % 60)
    
    return String(hrs) + ":" + String(mins).leftPadding(toLength: 2, withPad: "0") + ":" + String(secs).leftPadding(toLength: 2, withPad: "0")
  }
  
  @objc func updateState(_ notification: NSNotification) {
    let loadStatus = Player.global.loadStatus
    
    if loadStatus == .loading {
      loadingIdc.isHidden = false
      loadingIdc.startAnimation(nil)
      artworkImg.isHidden = true
    } else {
      loadingIdc.isHidden = true
      loadingIdc.stopAnimation(nil)
      artworkImg.isHidden = false
    }
    
    
  }
  
  @objc func updateTimeState(_ notification: NSNotification) {
    let duration = Player.global.duration
    let position = Player.global.position
    
    playedDurationLbl.stringValue = formatTime(total: Int(position))
    playedRemainingLbl.stringValue = formatTime(total: Int(duration - position))
    
    seekSlider.minValue = 0
    seekSlider.maxValue = duration
    seekSlider.doubleValue = position
    seekSlider.streamedValue = Player.global.buffered
  }
  
  @objc func seek(_ sender: Any) {
    let event = NSApplication.shared.currentEvent
    // Only react to dragging so that we don't skip back after slider release
    if event?.type == .leftMouseDragged {
      Player.global.seek(seconds: seekSlider.doubleValue)
    }
  }
  
  static private func controlX(_ view: NSView) -> CGFloat {
    return view.frame.origin.x + view.frame.size.width
  }
}
