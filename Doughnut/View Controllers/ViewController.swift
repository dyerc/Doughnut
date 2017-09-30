//
//  ViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 22/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class ViewController: NSSplitViewController {
  enum Events:String {
    case PodcastSelected = "PodcastSelected"
    
    var notification: Notification.Name {
      return Notification.Name(rawValue: self.rawValue)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    
  }

  @IBAction func play(_ sender: NSSegmentedControl) {
    let alert = NSAlert()
    alert.messageText = "Hello World"
    alert.runModal()
  }
  
}

