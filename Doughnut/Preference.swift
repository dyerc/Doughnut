//
//  Preference.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class Preference {
  static func libraryPath() -> URL {
    #if DEBUG
      let env = ProcessInfo.processInfo.environment
      var path: URL
      print(env)
      if env["TEST"] != nil {
        path = Preference.userMusicPath().appendingPathComponent("Doughnut_test")
        print("TEST Library \(path)")
      } else {
        path = Preference.userMusicPath().appendingPathComponent("Doughnut_dev")
        print("DEBUG Library \(path)")
      }
    #else
      let path = Preference.userMusicPath().appendingPathComponent("Doughnut")
    #endif
    
    var isDir = ObjCBool(true)
    if FileManager.default.fileExists(atPath: path.absoluteString, isDirectory: &isDir) == false {
      do {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
      } catch {}
    }
    
    return path
  }
  
  private static func userMusicPath() -> URL {
    if let path = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first {
      return path
    } else {
      return URL(string: NSHomeDirectory())!
    }
  }
}
