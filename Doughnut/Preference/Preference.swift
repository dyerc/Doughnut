//
//  Preference.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

protocol InitializingFromKey {
  static var defaultValue: Self { get }
  init?(key: Preference.Key)
}

class Preference {
  
  struct Key: RawRepresentable {
    typealias RawValue = String
    var rawValue: String
    
    init(_ string: String) { self.rawValue = string }
    init?(rawValue: RawValue) { self.rawValue = rawValue }
    
    // Library
    static let reloadFrequency = Key("reloadFrequency")
    
    // Playback
    static let skipForwardDuration = Key("skipForwardDuration")
    static let skipBackDuration = Key("skipBackDuration")
  }
  
  static let kLibraryPath = "LibraryPath"
  static let kVolume = "Volume"
  
  static let defaultPreference:[String: Any] = [
    Key.reloadFrequency.rawValue: 60,
    
    Key.skipBackDuration.rawValue: 30,
    Key.skipForwardDuration.rawValue: 30
  ]
  
  static private let ud = UserDefaults.standard
  
  static func object(for key: Key) -> Any? {
    return ud.object(forKey: key.rawValue)
  }
  
  static func array(for key: Key) -> [Any]? {
    return ud.array(forKey: key.rawValue)
  }
  
  static func url(for key: Key) -> URL? {
    return ud.url(forKey: key.rawValue)
  }
  
  static func dictionary(for key: Key) -> [String : Any]? {
    return ud.dictionary(forKey: key.rawValue)
  }
  
  static func string(for key: Key) -> String? {
    return ud.string(forKey: key.rawValue)
  }
  
  static func stringArray(for key: Key) -> [String]? {
    return ud.stringArray(forKey: key.rawValue)
  }
  
  static func data(for key: Key) -> Data? {
    return ud.data(forKey: key.rawValue)
  }
  
  static func bool(for key: Key) -> Bool {
    return ud.bool(forKey: key.rawValue)
  }
  
  static func integer(for key: Key) -> Int {
    return ud.integer(forKey: key.rawValue)
  }
  
  static func float(for key: Key) -> Float {
    return ud.float(forKey: key.rawValue)
  }
  
  static func double(for key: Key) -> Double {
    return ud.double(forKey: key.rawValue)
  }
  
  static func value(for key: Key) -> Any? {
    return ud.value(forKey: key.rawValue)
  }
  
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
