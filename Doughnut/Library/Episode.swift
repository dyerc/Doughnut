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
import AVFoundation
import Foundation

import FeedKit
import GRDB

class Episode: Record {
  var id: Int64?
  var podcastId: Int64?
  var title: String
  var description: String?
  var guid: String
  var pubDate: Date?
  var link: String?
  var enclosureUrl: String?
  var enclosureSize: Int64?
  var fileName: String?
  var favourite: Bool = false
  var downloaded: Bool = false
  var played: Bool = false
  var playPosition: Int = 0
  var duration: Int = 0

  var podcast: Podcast?

  var artwork: NSImage?

  // Not persisted, set by task queue to prevent duplicate downloads
  var downloading: Bool = false

  var plainDescription: String? {
    get {
      guard let description = description else { return nil }
      return description.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil).trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  override class var databaseTableName: String {
    return "episodes"
  }

  init(title: String, guid: String) {
    self.title = title
    self.guid = guid
    self.pubDate = Date()

    super.init()
  }

  required init(row: Row) {
    id = row["id"]
    podcastId = row["podcast_id"]
    title = row["title"]
    description = row["description"]
    guid = row["guid"]
    pubDate = row["pub_date"]
    link = row["link"]
    enclosureUrl = row["enclosure_url"]
    enclosureSize = row["enclosure_size"]
    fileName = row["file_name"]
    favourite = row["favourite"]
    downloaded = row["downloaded"]
    played = row["played"]
    playPosition = row["play_position"]
    duration = row["duration"]

    super.init(row: row)
  }

  override func encode(to container: inout PersistenceContainer) {
    container["id"] = id

    if let podcast = podcast {
      container["podcast_id"] = podcast.id
    } else {
      container["podcast_id"] = podcastId
    }

    container["title"] = title
    container["description"] = description
    container["guid"] = guid
    container["pub_date"] = pubDate
    container["link"] = link
    container["enclosure_url"] = enclosureUrl
    container["enclosure_size"] = enclosureSize
    container["file_name"] = fileName
    container["favourite"] = favourite
    container["downloaded"] = downloaded
    container["played"] = played
    container["play_position"] = playPosition
    container["duration"] = duration
  }

  override func didInsert(with rowID: Int64, for column: String?) {
    id = rowID
  }

  func invalid() -> String? {
    if title.isEmpty {
      return "Episode must have a title"
    }

    return nil
  }

  func download() {
    guard let podcast = podcast else { return }

    if !downloading {
      Library.global.tasks.run(EpisodeDownloadTask(episode: self, podcast: podcast))
      downloading = true
    }
  }

  func file() -> String {
    if let fileName = fileName {
      return fileName
    } else {
      guard let url = URL(string: enclosureUrl ?? "unknown.mp3") else { return "unknown.mp3" }
      let fileUrl = Utils.removeQueryString(url: url).absoluteString
      let enclosureType = NSString(string: fileUrl).pathExtension
      return Library.sanitizePath(title) + "." + enclosureType
    }
  }

  func url() -> URL? {
    guard let podcast = podcast else { return nil }

    if let podcastUrl = podcast.storagePath(), let fileName = fileName {
      return podcastUrl.appendingPathComponent(fileName)
    } else {
      return nil
    }
  }

  func uniqueFile() -> String {
    guard let url = URL(string: enclosureUrl ?? "unknown.mp3") else { return "unknown.mp3" }
    let fileUrl = Utils.removeQueryString(url: url).absoluteString
    let enclosureType = NSString(string: fileUrl).pathExtension

    return Library.sanitizePath(title) + "_\(Int(arc4random_uniform(999) + 1))." + enclosureType
  }

  func invokeSave(dbQueue: DatabaseQueue) -> Bool {
    do {
      try dbQueue.inDatabase { db in
        try self.save(db)
      }
    } catch let error as DatabaseError {
      Library.handleDatabaseError(error)
      return false
    } catch {
      return false
    }

    return true
  }

  func parse(feedItem: RSSFeedItem) {
    guard let title = feedItem.title else { return }
    guard let guid = feedItem.guid?.value else { return }

    self.title = title
    self.guid = guid
    description = feedItem.description
    pubDate = feedItem.pubDate
    link = feedItem.link

    if let duration = feedItem.iTunes?.iTunesDuration {
      self.duration = Int(duration)
    }

    if let enclosure = feedItem.enclosure?.attributes {
      enclosureUrl = enclosure.url
      enclosureSize = enclosure.length
    }
  }

  func moveToTrash(completion: ((_ url: URL) -> Void)? = nil) {
    if let url = url() {
      NSWorkspace.shared.recycle([url], completionHandler: { _, error in
        if let error = error {
          Library.log(level: .error, "Failed to move to trash \(error)")
        } else {
          if let completion = completion {
            completion(url)
          }
        }
      })
    }
  }

  static func fromFile(podcast: Podcast, url: URL, copyToLibrary: Bool, completion: @escaping (_ episode: Episode) -> Void) {
    DispatchQueue.global(qos: .background).async {
      let asset = AVAsset(url: url)
      var title = url.deletingPathExtension().lastPathComponent

      for item in asset.commonMetadata {
        if item.commonKey?.rawValue == "title", let value = item.value {
          title = value as! String
        }
      }

      let episode = Episode(title: title, guid: NSUUID().uuidString)
      episode.podcast = podcast
      episode.podcastId = podcast.id
      episode.downloaded = true
      episode.enclosureUrl = url.absoluteString

      if copyToLibrary {
        // Perform the copy
        guard let storagePath = podcast.storagePath() else {
          Library.log(level: .error, "Could not determine podcast storage location")
          return
        }

        var fileName = episode.file()
        var outputPath = storagePath.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: outputPath.path) {
          fileName = episode.uniqueFile()
          outputPath = storagePath.appendingPathComponent(fileName)
        }

        do {
          try FileManager.default.copyItem(at: url, to: outputPath)

          episode.fileName = fileName
        } catch {
          Library.log(level: .error, "Failed to copy \(url.path) to library. Output destination \(outputPath)")
          return
        }
      } else {
        episode.fileName = url.path
      }

      for item in asset.commonMetadata {
        if let key = item.commonKey, let value = item.value {
          if key.rawValue == "artwork" {
            episode.artwork = NSImage(data: value as! Data)
          }

          if key.rawValue == "description" {
            episode.description = value as? String
          }
        }
      }

      DispatchQueue.main.async {
        completion(episode)
      }
    }
  }
}
