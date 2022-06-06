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

import AppKit

import MASPreferences

final class PrefAdvancedViewController: NSViewController, MASPreferencesViewController {

  static func instantiate() -> PrefAdvancedViewController {
    let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
    return storyboard.instantiateController(withIdentifier: "PrefAdvancedViewController") as! PrefAdvancedViewController
  }

  @objc var viewIdentifier: String = "PrefAdvancedViewController"

  @objc var toolbarItemImage: NSImage? {
    if #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil)!
    } else {
      return NSImage(named: NSImage.advancedName)
    }
  }

  @objc var toolbarItemLabel: String? {
    view.layoutSubtreeIfNeeded()
    return "Advanced"
  }

  @objc var hasResizableWidth: Bool = false
  @objc var hasResizableHeight: Bool = false

}
