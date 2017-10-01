//
//  PlayerView.swift
//  Doughnut
//
//  Created by Chris Dyer on 01/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class PlayerView: NSView {
  let width = 420
  
  var artworkImg: NSImageView!
  var reverseBtn: NSButton!
  var playBtn: NSButton!
  var forwardBtn: NSButton!
  var playedDurationLbl: NSTextField!
  var seekSlider: NSSlider!
  var playedRemainingLbl: NSTextField!
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }
  
  required init?(coder decoder: NSCoder) {
    artworkImg = NSImageView(frame: NSRect(x: 0, y: 3, width: 20, height: 20))
    
    reverseBtn = NSButton.init(frame: NSRect(x: PlayerView.controlX(artworkImg) + 6, y: 0, width: 28, height: 25))
    playBtn = NSButton.init(frame: NSRect(x: PlayerView.controlX(reverseBtn) + 1, y: 0, width: 28, height: 25))
    forwardBtn = NSButton.init(frame: NSRect(x: PlayerView.controlX(playBtn) + 1, y: 0, width: 28, height: 25))
    
    playedDurationLbl = NSTextField(frame: NSRect(x: PlayerView.controlX(forwardBtn) + 2, y: 6, width: 50, height: 14))
    seekSlider = NSSlider(frame: NSRect(x: PlayerView.controlX(playedDurationLbl) + 4, y: 4, width: 200, height: 18))
    playedRemainingLbl = NSTextField(frame: NSRect(x: PlayerView.controlX(seekSlider) + 4, y: 6, width: 50, height: 14))
    
    super.init(coder: decoder)
    
    wantsLayer = true
    layer?.backgroundColor = NSColor.red.cgColor
    
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
  
  @objc func updateState(_ notification: NSNotification) {
    let loadStatus = Player.global.loadStatus
    
    if loadStatus == .loading {
      
    }
    
    if loadStatus == .playing {
      
    }
  }
  
  @objc func updateTimeState(_ notification: NSNotification) {
    
  }
  
  static private func controlX(_ view: NSView) -> CGFloat {
    return view.frame.origin.x + view.frame.size.width
  }
}
