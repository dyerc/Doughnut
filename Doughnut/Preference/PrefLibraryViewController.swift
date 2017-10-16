//
//  PrefGeneralViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 16/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa
import MASPreferences

@objcMembers
class PrefLibraryViewController: NSViewController, MASPreferencesViewController {
  static func instantiate() -> PrefLibraryViewController {
    let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Preferences"), bundle: nil)
    return storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("PrefLibraryViewController")) as! PrefLibraryViewController
  }
  
  var viewIdentifier: String {
    get {
      return "library"
    }
  }
  
  var toolbarItemImage: NSImage? {
    get {
      return NSImage(named: .preferencesGeneral)!
    }
  }
  
  var toolbarItemLabel: String? {
    get {
      view.layoutSubtreeIfNeeded()
      return NSLocalizedString("Library", comment: "Library Preferences")
    }
  }
  
  var hasResizableWidth: Bool = false
  var hasResizableHeight: Bool = false
}
