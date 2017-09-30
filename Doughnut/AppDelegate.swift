//
//  AppDelegate.swift
//  Doughnut
//
//  Created by Chris Dyer on 22/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let connected = Library.global.connect()
    
    if !connected {
      let alert = NSAlert()
      alert.messageText = "Failed to connect to library"
      alert.runModal()
      abort()
    }
    
    //  Library.global.subscribe(url: "http://feeds.feedburner.com/TellEmSteveDave")
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }


}

