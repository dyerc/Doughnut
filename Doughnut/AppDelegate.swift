//
//  AppDelegate.swift
//  Doughnut
//
//  Created by Chris Dyer on 22/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa
import MASPreferences

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  lazy var preferencesWindowController: NSWindowController = {
    return MASPreferencesWindowController(viewControllers: [
      PrefLibraryViewController.instantiate()
      ], title: "Doughnut Preferences")
  }()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    UserDefaults.standard.register(defaults: Preference.defaultPreference)
    
    print("Check for updates every \(Preference.string(for: Preference.Key.reloadFrequency))")
    
    /*do {
      try Player.audioOutputDevices()
    } catch {}*/
    
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

  @IBAction func showPreferences(_ sender: AnyObject) {
    preferencesWindowController.showWindow(self)
  }
}

