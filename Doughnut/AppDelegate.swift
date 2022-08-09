/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 - 2022 Chris Dyer
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

private extension NSUserInterfaceItemIdentifier {

  static let doughnutMainMenuDebug = Self("NSDoughnutMainMenuDebug")

  static let doughnutViewMenuSortPodcasts = Self("NSDoughnutViewMenuSortPodcastsItem")
  static let doughnutViewMenuSortEpisodes = Self("NSDoughnutViewMenuSortEpisodesItem")
  static let doughnutControlMenu = Self("NSDoughnutControlMenuItem")

}

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {

  var mainWindowController: WindowController?

  lazy var preferencesWindowController: NSWindowController = {
    return MASPreferencesWindowController(viewControllers: [
      PrefGeneralViewController.instantiate(),
      PrefPlaybackViewController.instantiate(),
      PrefLibraryViewController.instantiate(),
      PrefAdvancedViewController.instantiate(),
      ], title: nil)
  }()

  private lazy var crashReportWindowController: CrashReportWindowController? = {
    return CrashReportWindowController.instantiateFromMainStoryboard()
  }()

  override init() {
    NSWindow.allowsAutomaticWindowTabbing = false
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    updateAppIcon(canRemoveCustomIcon: false)

    // Register NSMenuDelegate for all main menu items
    NSApp.mainMenu?.items.forEach { item in
      if item.identifier == .doughnutMainMenuDebug {
        item.isHidden = !Preference.bool(for: .debugMenuEnabled)
      }
      item.submenu?.delegate = self
    }

    UserDefaults.standard.register(defaults: Preference.defaultPreference)

    UserDefaults.standard.addObserver(self, forKeyPath: Preference.Key.appIconStyle.rawValue, options: [], context: nil)
    UserDefaults.standard.addObserver(self, forKeyPath: Preference.Key.debugMenuEnabled.rawValue, options: [], context: nil)

    /*do {
      try Player.audioOutputDevices()
    } catch {}*/

    createAndShowMainWindow()

    showCrashReportWindowIfNeeded()

    let connected = Library.global.connect()

    if !connected {
      abort()
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    mainWindowController?.showWindow(self)
    return false
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    Player.global.stop()
  }

  func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let menu = NSMenu()
    menu.items = ControlMenuProvider.shared.buildControlMenuItems(isForDockMenu: true)
    return menu
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    switch keyPath {
    case Preference.Key.appIconStyle.rawValue?:
      updateAppIcon(canRemoveCustomIcon: true)
    case Preference.Key.debugMenuEnabled.rawValue?:
      NSApp.mainMenu?.items.forEach { item in
        if item.identifier == .doughnutMainMenuDebug {
          item.isHidden = !Preference.bool(for: .debugMenuEnabled)
        }
      }
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

  private func updateAppIcon(canRemoveCustomIcon: Bool) {
    guard let iconStyle = Preference.AppIconStyle(rawValue: Preference.integer(for: Preference.Key.appIconStyle)) else {
      return
    }

    let bundlePath = Bundle.main.bundlePath

    switch iconStyle {
    case .catalina:
      if canRemoveCustomIcon {
        // Setting applicationIconImage to nil won't clear the icon if custom icon is set
        let iconImage = NSImage(named: "AppIcon")
        NSApp.applicationIconImage = iconImage
        NSWorkspace.shared.setIcon(nil, forFile: bundlePath, options: [])
      }
    case .bigSur:
      let iconImage = NSImage(named: "AppIcon_Big_Sur")
      NSApp.applicationIconImage = iconImage
      NSWorkspace.shared.setIcon(iconImage, forFile: bundlePath, options: [])
    }
  }

  @IBAction func showPreferences(_ sender: AnyObject) {
    preferencesWindowController.showWindow(self)
  }

  @IBAction func rename(_ sender: AnyObject) {
    assert(false, "This menu item is to be implmented: \(#function)")
  }

  @IBAction func deleteAllPlayed(_ sender: AnyObject) {
    assert(false, "This menu item is to be implemented: \(#function)")
  }

  @IBAction func forceCrash(_ sender: AnyObject) {
    CrashReporter.shared.forceCrash()
  }

}

extension AppDelegate {

  @discardableResult
  private func showCrashReportWindowIfNeeded() -> Bool {
    guard
      let crashContent = CrashReporter.shared.getPendingCrashReport(),
      let crashReportWindowController = crashReportWindowController,
      let crashReportWindow = crashReportWindowController.window
    else {
      return false
    }

    crashReportWindowController.setCrashContent(crashContent)

    NSApp.runModal(for: crashReportWindow)

    return true
  }

}

extension AppDelegate: NSMenuDelegate {

  func menuNeedsUpdate(_ menu: NSMenu) {
    if let menuItem = menu.menuItem, let identifier = menuItem.identifier {
      switch identifier {
      case .doughnutControlMenu:
        menu.items = ControlMenuProvider.shared.buildControlMenuItems(isForDockMenu: false)
      default:
        break
      }
    }

    for menuItem in menu.items {
      // Hide main menu items that is not impelemented for release build.
      switch menuItem.action {
      case #selector(rename(_:)):
#if !DEBUG
        menuItem.isHidden = true
#endif
      case #selector(deleteAllPlayed(_:)):
#if !DEBUG
        menuItem.isHidden = true
#endif
      default:
        break
      }
      if let itemIdentifier = menuItem.identifier {
        switch itemIdentifier {
        case .doughnutViewMenuSortPodcasts:
          menuItem.submenu = SortingMenuProvider.Shared.podcasts.build(forStyle: .mainMenu)
        case .doughnutViewMenuSortEpisodes:
          menuItem.submenu = SortingMenuProvider.Shared.episodes.build(forStyle: .mainMenu)
        default:
          break
        }
      }
    }
  }

}
