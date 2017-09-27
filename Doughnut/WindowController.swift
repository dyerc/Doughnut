//
//  WindowController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
  @IBOutlet weak var toolbarPlayer: NSToolbarItem!
  @IBOutlet var toolbarPlayerView: NSView!
  
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.titleVisibility = .hidden
    
    Bundle.main.loadNibNamed(NSNib.Name(rawValue: "ToolbarPlayer"), owner: self, topLevelObjects: nil)
    toolbarPlayerView.bounds = (toolbarPlayer.view?.bounds)!
    toolbarPlayer.view = toolbarPlayerView
  }
}
