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
  var mediaKeyTap: SPMediaKeyTap?

  lazy var preferencesWindowController: NSWindowController = {
    return MASPreferencesWindowController(viewControllers: [
      PrefLibraryViewController.instantiate()
      ], title: "Doughnut Preferences")
  }()
  
  override init() {
    UserDefaults.standard.register(
      defaults: [kMediaKeyUsingBundleIdentifiersDefaultsKey : SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()])
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    UserDefaults.standard.register(defaults: Preference.defaultPreference)
    
    print("Check for updates every \(Preference.string(for: Preference.Key.reloadFrequency))")
    
    mediaKeyTap = SPMediaKeyTap(delegate: self)
    if SPMediaKeyTap.usesGlobalMediaKeyTap() {
      mediaKeyTap?.startWatchingMediaKeys()
    }
    
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
  
  override func mediaKeyTap(_ keyTap: SPMediaKeyTap!, receivedMediaKeyEvent event: NSEvent!) {
    let keyCode = Int((event.data1 & 0xFFFF0000) >> 16);
    let keyFlags = (event.data1 & 0x0000FFFF);
    let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    
    if (keyIsPressed) {
      switch keyCode {
      case Int(NX_KEYTYPE_PLAY):
        Player.global.play()
        
      case Int(NX_KEYTYPE_FAST):
        Player.global.skipAhead()
        
      case Int(NX_KEYTYPE_REWIND):
        Player.global.skipBack()
        
      default:
        break
      }
    }
  }

  @IBAction func showPreferences(_ sender: AnyObject) {
    preferencesWindowController.showWindow(self)
  }
}

