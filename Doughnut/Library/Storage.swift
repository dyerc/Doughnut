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

import Foundation

class Storage {
  static func librarySize() -> String? {
    guard let libraryUrl = Preference.url(for: Preference.Key.libraryPath) else { return nil }

    guard let size = Storage.folderSize(libraryUrl) else { return nil }

    let byteFormatter = ByteCountFormatter()
    byteFormatter.allowedUnits = .useGB
    byteFormatter.countStyle = .file
    return byteFormatter.string(fromByteCount: size)
  }

  static func podcastSize(_ podcast: Podcast) -> String? {
    guard let url = podcast.storagePath() else { return nil }

    guard let size = Storage.folderSize(url) else { return nil }

    let byteFormatter = ByteCountFormatter()
    byteFormatter.allowedUnits = .useMB
    byteFormatter.countStyle = .file

    if size > (1024 * 1024 * 1024) {
      byteFormatter.allowedUnits = .useGB
    }

    return byteFormatter.string(fromByteCount: size)
  }

  static func folderSize(_ url: URL) -> Int64? {
    var bool: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &bool) {
      var folderSize = 0
      FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])?.forEach({
        guard let url = $0 as? URL,
              let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        else {
          return
        }
        folderSize += fileSize
      })

      return Int64(folderSize)
    }

    return nil
  }
}
