//
//  WindowController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {
  @IBOutlet var allToggle: NSButton!
  @IBOutlet var newToggle: NSButton!
  @IBOutlet var playerView: NSToolbarItem!
  
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.titleVisibility = .hidden
  }
  
  @IBAction func subscribeToPodcast(_ sender: Any) {
    let subscribeAlert = NSAlert()
    subscribeAlert.messageText = "Podcast feed URL"
    subscribeAlert.addButton(withTitle: "Ok")
    subscribeAlert.addButton(withTitle: "Cancel")
    
    let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
    input.stringValue = ""
    
    subscribeAlert.accessoryView = input
    let button = subscribeAlert.runModal()
    if button == .alertFirstButtonReturn {
      Library.global.subscribe(url: input.stringValue)
    }
  }
  
  @IBAction func toggleAllEpisodes(_ sender: Any) {
    allToggle.state = .on
    newToggle.state = .off
  }
  
  @IBAction func toggleNewEpisodes(_ sender: Any) {
    allToggle.state = .off
    newToggle.state = .on
  }
  
  func windowDidResignKey(_ notification: Notification) {
    if let player = playerView.view as? PlayerView {
      player.needsDisplay = true
    }
  }
  
  func windowDidBecomeKey(_ notification: Notification) {
    if let player = playerView.view as? PlayerView {
      player.needsDisplay = true
    }
  }
}
