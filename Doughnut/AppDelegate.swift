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
      ], title: nil)
  }()

  override init() {
    NSWindow.allowsAutomaticWindowTabbing = false
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Register NSMenuDelegate for all main menu items
    NSApp.mainMenu?.items.forEach {
      $0.submenu?.delegate = self
    }

    UserDefaults.standard.register(defaults: Preference.defaultPreference)

    /*do {
      try Player.audioOutputDevices()
    } catch {}*/

    createAndShowMainWindow()

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

  private func createAndShowMainWindow() {
    if mainWindowController == nil {
      mainWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateInitialController()
    }
    mainWindowController?.showWindow(self)
  }

  @IBAction func showPreferences(_ sender: AnyObject) {
    preferencesWindowController.showWindow(self)
  }

  @IBAction func popUpContextualMenu(_ sender: Any) {
    guard
      let senderView = sender as? NSView,
      let menu = senderView.menu,
      let event = NSApp.currentEvent
    else {
      return
    }
    NSMenu.popUpContextMenu(menu, with: event, for: senderView)
  }

  @IBAction func rename(_ sender: AnyObject) {
    assert(false, "This menu item is to be implemented: \(#function)")
  }

  @IBAction func deleteAllPlayed(_ sender: AnyObject) {
    assert(false, "This menu item is to be implemented: \(#function)")
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
          menuItem.submenu = SortingMenuProvider.Shared.podcasts.buildMenu()
        case .doughnutViewMenuSortEpisodes:
          menuItem.submenu = SortingMenuProvider.Shared.episodes.buildMenu()
        default:
          break
        }
      }
    }
  }

}
