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

class PrefLibraryViewController: NSViewController {
  static func instantiate() -> PrefLibraryViewController {
    let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
    return storyboard.instantiateController(withIdentifier: "PrefLibraryViewController") as! PrefLibraryViewController
  }

  var viewIdentifier: String = "PrefLibraryViewController"

  var toolbarItemImage: NSImage {
    get {
      return NSImage(named: "PrefLibrary")!
    }
  }

  var toolbarItemLabel: String? {
    get {
      view.layoutSubtreeIfNeeded()
      return "  Library  "
    }
  }

  override func viewDidAppear() {
    super.viewDidAppear()

    calculateLibrarySize()
  }

  var hasResizableWidth: Bool = false
  var hasResizableHeight: Bool = false

  @IBOutlet weak var librarySizeTxt: NSTextField!

  func calculateLibrarySize() {
    if let librarySize = Storage.librarySize() {
      librarySizeTxt.stringValue = librarySize
    }
  }

  @IBAction func changeLibraryLocation(_ sender: Any) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK {
      if let url = panel.url {
        Preference.set(url, for: Preference.Key.libraryPath)

        let alert = NSAlert()
        alert.addButton(withTitle: "Ok")
        alert.messageText = "Doughnut Will Restart"
        alert.informativeText = "Please relaunch Doughnut in order to use the new library location"

        alert.runModal()
        exit(0)
      }
    }
  }

  @IBAction func revealLibraryFinder(_ sender: Any) {
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: Preference.url(for: Preference.Key.libraryPath)?.path ?? "~")
  }
}
