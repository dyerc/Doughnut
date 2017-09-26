//
//  WindowController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.titleVisibility = .hidden
  }
}
