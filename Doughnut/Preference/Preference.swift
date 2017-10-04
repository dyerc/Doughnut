//
//  Preference.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class Preference {
  static let kLibraryPath = "LibraryPath"
  static let kVolume = "Volume"
  
  static func testEnv() -> Bool {
    return ProcessInfo.processInfo.environment["TEST"] != nil
  }
  
  static func libraryPath() -> URL? {
    if testEnv() {
      return defaultLibraryPath()
    } else {
      if let path = UserDefaults.standard.string(forKey: kLibraryPath) {
        return URL(fileURLWithPath: path)
      } else {
        return nil
      }
    }
  }
  
  static func defaultLibraryPath() -> URL {
    var path: URL    
    if testEnv() {
      print("Using test library")
      path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Doughtnut_test")
    } else {
      #if DEBUG
        path = Preference.userMusicPath().appendingPathComponent("Doughnut_dev")
      #else
        path = Preference.userMusicPath().appendingPathComponent("Doughnut")
      #endif
    }
    
    createLibraryIfNotExists(path)
    
    return path
  }
  
  static func createLibraryIfNotExists(_ url: URL) {
    var isDir = ObjCBool(true)
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) == false {
      do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("Failed to create directory \(error)")
      }
    }
  }
  
  private static func userMusicPath() -> URL {
    if let path = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first {
      return path
    } else {
      return URL(string: NSHomeDirectory())!
    }
  }
}
