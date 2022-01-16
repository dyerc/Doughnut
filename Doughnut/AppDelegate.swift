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

  var mainWindowController: WindowController?

  lazy var preferencesWindowController: NSWindowController = {
    return MASPreferencesWindowController(viewControllers: [
      PrefGeneralViewController.instantiate(),
      PrefPlaybackViewController.instantiate(),
      PrefLibraryViewController.instantiate(),
      ], title: nil)
  }()

  override init() {
    NSWindow.allowsAutomaticWindowTabbing = false

    UserDefaults.standard.register(
      defaults: [kMediaKeyUsingBundleIdentifiersDefaultsKey: SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()!])
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    UserDefaults.standard.register(defaults: Preference.defaultPreference)

    mediaKeyTap = SPMediaKeyTap(delegate: self)

    UserDefaults.standard.addObserver(self, forKeyPath: Preference.Key.enableMediaKeys.rawValue, options: [], context: nil)
    if Preference.bool(for: Preference.Key.enableMediaKeys) {
      setupMediaKeyTap()
    }

    /*do {
      try Player.audioOutputDevices()
    } catch {}*/

    let connected = Library.global.connect()

    if !connected {
      abort()
    }

    createAndShowMainWindow()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    mainWindowController?.showWindow(self)
    return false
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    switch keyPath {
    case Preference.Key.enableMediaKeys.rawValue?:
      setupMediaKeyTap()
    default:
      return
    }
  }

  private func createAndShowMainWindow() {
    if mainWindowController == nil {
      mainWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateInitialController()
    }
    mainWindowController?.showWindow(self)
  }

  func setupMediaKeyTap() {
    guard let mediaKeyTap = mediaKeyTap else { return }

    if Preference.bool(for: Preference.Key.enableMediaKeys) {
      if SPMediaKeyTap.usesGlobalMediaKeyTap() {
        mediaKeyTap.startWatchingMediaKeys()
      }
    } else {
      mediaKeyTap.stopWatchingMediaKeys()
    }
  }

  override func mediaKeyTap(_ keyTap: SPMediaKeyTap!, receivedMediaKeyEvent event: NSEvent!) {
    let keyCode = Int((event.data1 & 0xFFFF0000) >> 16)
    let keyFlags = (event.data1 & 0x0000FFFF)
    let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA

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

  @IBAction func rename(_ sender: AnyObject) {
    assert(false, "This menu item is to be implemented: \(#function)")
  }

  @IBAction func deleteAllPlayed(_ sender: AnyObject) {
    assert(false, "This menu item is to be implemented: \(#function)")
  }

  @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    // Hide main menu items that is not impelemented for release build.
    switch menuItem.action {
    case #selector(rename(_:)):
#if !DEBUG
      menuItem.isHidden = true
#endif
      break
    case #selector(deleteAllPlayed(_:)):
#if !DEBUG
      menuItem.isHidden = true
#endif
      break
    default:
      break
    }
    return true
  }

}
