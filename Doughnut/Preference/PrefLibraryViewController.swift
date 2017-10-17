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
  
  override func viewDidAppear() {
    super.viewDidAppear()
    
    calculateLibrarySize()
  }
  
  var hasResizableWidth: Bool = false
  var hasResizableHeight: Bool = false
  
  @IBOutlet weak var librarySizeTxt: NSTextField!
  
  func calculateLibrarySize() {
    if let libraryUrl = Preference.url(for: Preference.Key.libraryPath) {
      var bool: ObjCBool = false
      if FileManager.default.fileExists(atPath: libraryUrl.path, isDirectory: &bool) {
        var folderSize = 0
        FileManager.default.enumerator(at: libraryUrl, includingPropertiesForKeys: [.fileSizeKey])?.forEach({
          folderSize += (try? ($0 as? URL)?.resourceValues(forKeys: [.fileSizeKey]))??.fileSize ?? 0
        })
        
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = .useGB
        byteFormatter.countStyle = .file
        
        librarySizeTxt.stringValue = byteFormatter.string(fromByteCount: Int64(folderSize))
      }
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
