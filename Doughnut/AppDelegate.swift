/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 Chris Dyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
    print(ProcessInfo.processInfo.arguments)
    
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
      abort()
    }
    
    //  Library.global.subscribe(url: "http://feeds.feedburner.com/TellEmSteveDave")
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      for window in sender.windows {
        window.makeKeyAndOrderFront(self)
      }
    }
    
    return true
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
        Player.global.togglePlay()
        
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

