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

    // Interface
    static let podcastSortParam = Key("podcastSortParam")
    static let podcastSortDirection = Key("podcastSortDirection")
    static let episodeSortParam = Key("episodeSortParam")
    static let episodeSortDirection = Key("episodeSortDirection")

    // General
    static let appIconStyle = Key("appIconStyle")
    static let showDockBadge = Key("showDockBadge")

    // Library
    static let libraryPath = Key("libraryPath")
    static let reloadFrequency = Key("reloadFrequency")

    // Playback
    static let skipForwardDuration = Key("skipForwardDuration")
    static let skipBackDuration = Key("skipBackDuration")
    static let replayAfterPause = Key("replayAfterPause")

    // Debugging
    static let debugMenuEnabled = Key("debugMenuEnabled")
    static let debugSQLTraceEnabled = Key("debugSQLTraceEnabled")
    static let debugDeveloperExtrasEnabled = Key("debugDeveloperExtrasEnabled")
  }

  enum AppIconStyle: Int {
    case catalina = 0
    case bigSur = 1
  }

  static let kLibraryPath = "LibraryPath"
  static let kVolume = "Volume"

  static var defaultLibraryPath: URL {
    get {
      return Preference.userMusicPath().appendingPathComponent("Doughnut")
    }
  }

  static let defaultPreference: [String: Any] = [
    Key.podcastSortParam.rawValue: "Title",
    Key.podcastSortDirection.rawValue: "Ascending",
    Key.episodeSortParam.rawValue: "Most Recent",
    Key.episodeSortDirection.rawValue: "Descending",

    Key.libraryPath.rawValue: defaultLibraryPath,
    Key.reloadFrequency.rawValue: 60,

    Key.skipBackDuration.rawValue: 30,
    Key.skipForwardDuration.rawValue: 30,

    Key.showDockBadge.rawValue: true,
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

  static func dictionary(for key: Key) -> [String: Any]? {
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

  static func set(_ value: Bool, for key: Key) {
    ud.set(value, forKey: key.rawValue)
  }

  static func set(_ value: Int, for key: Key) {
    ud.set(value, forKey: key.rawValue)
  }

  static func set(_ value: String, for key: Key) {
    ud.set(value, forKey: key.rawValue)
  }

  static func set(_ value: Float, for key: Key) {
    ud.set(value, forKey: key.rawValue)
  }

  static func set(_ value: Double, for key: Key) {
    ud.set(value, forKey: key.rawValue)
  }

  static func set(_ value: Any, for key: Key) {
    ud.set(value, forKey: key.rawValue)
  }

  static func set(_ value: URL, for key: Key) {
    ud.set(value, forKey: key.rawValue)
  }

  static func testEnv() -> Bool {
    if ProcessInfo.processInfo.arguments.contains("UI-TEST") {
      return true
    }

    return ProcessInfo.processInfo.environment["TEST"] != nil
  }

  static func libraryPath() -> URL {
    if testEnv() {
      let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Doughtnut_test")
      try? FileManager.default.removeItem(at: url)
      createLibraryIfNotExists(url)
      return url
    } else {
      #if DEBUG
        let url = Preference.userMusicPath().appendingPathComponent("Doughnut_dev")
        createLibraryIfNotExists(url)
        return url
      #else
        if let url = Preference.url(for: Key.libraryPath) {
          if url == defaultLibraryPath {
            createLibraryIfNotExists(url)
          }
          return url
        } else {
          return defaultLibraryPath
        }
      #endif
    }
  }

  static func createLibraryIfNotExists(_ url: URL) {
    var isDir = ObjCBool(true)
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) == false {
      do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Library.log(level: .error, "Failed to create directory \(error)")
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
