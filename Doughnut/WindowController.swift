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
  
  lazy var downloadsViewController: DownloadsViewController = {
    return self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "DownloadsPopover")) as! DownloadsViewController
  }()
  
  lazy var subscribeViewController: SubscribeViewController = {
    return self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SubscribeViewController")) as! SubscribeViewController
  }()
  
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.titleVisibility = .hidden
  }
  
  @IBAction func subscribeToPodcast(_ sender: Any) {
    /*let subscribeAlert = NSAlert()
    subscribeAlert.messageText = "Podcast feed URL"
    subscribeAlert.addButton(withTitle: "Ok")
    subscribeAlert.addButton(withTitle: "Cancel")
    
    let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
    input.stringValue = ""
    
    subscribeAlert.accessoryView = input
    let button = subscribeAlert.runModal()
    if button == .alertFirstButtonReturn {
      Library.global.subscribe(url: input.stringValue)
    }*/
    
    contentViewController?.presentViewControllerAsSheet(subscribeViewController)
  }
  
  @IBAction func showDownloads(_ button: NSButton) {
    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = downloadsViewController
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
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
  
  // Control Menu
  @IBAction func playerBackward(_ sender: Any) {
    Player.global.skipBack()
  }
  
  @IBAction func playerPlay(_ sender: Any) {
    Player.global.play()
  }
  
  @IBAction func playerForward(_ sender: Any) {
    Player.global.skipAhead()
  }
  
  @IBAction func volumeUp(_ sender: Any) {
    let current = Player.global.volume
    Player.global.volume = min(current + 0.1, 1.0)
  }
  
  @IBAction func volumeDown(_ sender: Any) {
    let current = Player.global.volume
    Player.global.volume = max(current - 0.1, 0.0)
  }
}
