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

class PrefPlaybackViewController: NSViewController, MASPreferencesViewController {
  static func instantiate() -> PrefPlaybackViewController {
    let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
    return storyboard.instantiateController(withIdentifier: "PrefPlaybackViewController") as! PrefPlaybackViewController
  }

  var viewIdentifier: String = "PrefPlaybackViewController"

  var toolbarItemImage: NSImage? {
    get {
      return NSImage(named: "PrefPlayback")
    }
  }

  var toolbarItemLabel: String? {
    get {
      view.layoutSubtreeIfNeeded()
      return " Playback "
    }
  }

  var hasResizableWidth: Bool = false
  var hasResizableHeight: Bool = false
}
