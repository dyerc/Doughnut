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
import Foundation

import FeedKit
import GRDB

class Podcast: Record {
  var id: Int64?
  var title: String
  var path: String
  var feed: String?
  var description: String?
  var link: String?
  var author: String?
  var language: String?
  var copyright: String?
  var pubDate: Date?
  private(set) var imageData: Data? {
    didSet {
      processThumbnailImage()
    }
  }
  var imageUrl: String?
  var lastParsed: Date?
  var subscribedAt: Date
  var autoDownload: Bool = false
  var reloadFrequency: Int = 0 // 0 is only manually reloaded

  private(set) var image: NSImage?

  var manualReload: Bool {
    get {
      return reloadFrequency == -1
    }
  }

  var defaultReload: Bool {
    get {
      return reloadFrequency == 0
    }
  }

  var episodes = [Episode]()

  var unplayedCount: Int {
    get {
      return episodes.reduce(0) {
        $0 + ($1.played == false ? 1 : 0)
      }
    }
  }

  var favouriteCount: Int {
    get {
      return episodes.reduce(0) {
        $0 + ($1.favourite ? 1 : 0)
      }
    }
  }

  var latestEpisode: Episode? {
    get {
      return episodes.sorted(by: { (a, b) -> Bool in
        guard let aD = a.pubDate else { return false }
        guard let bD = b.pubDate else { return true }

        return aD < bD
      }).last
    }
  }

  var loading = false

  override class var databaseTableName: String {
    return "podcasts"
  }

  init(title: String) {
    self.title = title
    self.path = Library.sanitizePath(title)
    self.subscribedAt = Date()

    super.init()
  }

  required init(row: Row) {
    id = row["id"]
    title = row["title"]
    path = row["path"]
    feed = row["feed"]
    description = row["description"]
    link = row["link"]
    author = row["author"]
    language = row["language"]
    copyright = row["copyright"]
    pubDate = row["pub_date"]

    if case let .blob(data) = (row["image"] as DatabaseValue).storage {
      imageData = data
    }

    imageUrl = row["image_url"]
    lastParsed = row["last_parsed"]
    subscribedAt = row["subscribed_at"]
    reloadFrequency = row["reload_frequency"]
    autoDownload = row["auto_download"]

    super.init(row: row)

    processThumbnailImage()
  }

  override func encode(to container: inout PersistenceContainer) {
    container["id"] = id
    container["title"] = title
    container["path"] = path
    container["feed"] = feed
    container["description"] = description
    container["link"] = link
    container["author"] = author
    container["language"] = language
    container["copyright"] = copyright
    container["pub_date"] = pubDate
    container["image"] = imageData
    container["image_url"] = imageUrl
    container["last_parsed"] = lastParsed
    container["subscribed_at"] = subscribedAt
    container["reload_frequency"] = reloadFrequency
    container["auto_download"] = autoDownload
  }

  override func didInsert(with rowID: Int64, for column: String?) {
    id = rowID

    for episode in episodes {
      episode.podcast = self
      episode.podcastId = self.id
    }
  }

  func storagePath() -> URL? {
    let pathUrl = URL(fileURLWithPath: self.path, relativeTo: Library.global.path)
    var isDir = ObjCBool(true)
    if FileManager.default.fileExists(atPath: pathUrl.path, isDirectory: &isDir) == false {
      do {
        try FileManager.default.createDirectory(at: pathUrl, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Library.log(level: .error, "Failed to create directory \(error)")
      }
    }

    return pathUrl
  }

  func loadEpisodes(db: Database) {
    do {
      episodes = try Episode.filter(Column("podcast_id") == self.id).fetchAll(db)

      for e in episodes {
        if e.podcastId == self.id {
          e.podcast = self
        }
      }
    } catch let error as DatabaseError {
      Library.handleDatabaseError(error)
    } catch {}
  }

  func deleteEpisode(episode: Episode) {
    guard episode.podcastId == self.id else { return }

    if let idx = episodes.firstIndex(where: { e -> Bool in return e.id == episode.id }) {
      episodes.remove(at: idx)
    }

    Library.global.delete(episode: episode)
  }

  func deleteEpisodeAndTrash(episode: Episode) {
    episode.moveToTrash { _ in
      self.deleteEpisode(episode: episode)
    }
  }

  func invalid() -> String? {
    if title.isEmpty {
      return "Podcast must have a title"
    }

    return nil
  }

  private func storeImage(_ url: URL) {
    imageUrl = url.absoluteString
    // TODO: Replace Data.init(contentsOf:options:) call with URLSessionDataTask
    if let downloadData = try? Data(contentsOf: url) {
      storeImage(downloadData)
    }
  }

  func storeImage(_ data: Data) {
    autoreleasepool {
      if
        let image = NSImage.downSampledImage(withData: data, dimension: 1024, scale: 1.0),
        let jpegData = image.jpegRepresentation()
      {
        imageData = jpegData
      }
    }
  }

  private func processThumbnailImage() {
    guard let imageData = imageData else { return }
    image = NSImage.downSampledImage(withData: imageData, dimension: 70, scale: 2.0)
  }

  // Called within subscribe or reload
  // 1. Update feed properties
  // 2. Check for new episodes
  func parse(feed: RSSFeed) -> [Episode] {
    self.description = feed.description
    self.link = feed.link
    self.author = feed.iTunes?.iTunesAuthor
    self.language = feed.language
    self.copyright = feed.copyright
    self.pubDate = feed.pubDate

    if let feedUrl = URL(string: self.feed ?? "") {
      // Prioritize iTunes image url over regular RSS
      if let iTunesImageUrl = feed.iTunes?.iTunesImage?.attributes?.href {
        if let imageUrl = URL(string: iTunesImageUrl, relativeTo: feedUrl) {
          storeImage(imageUrl)
        }
      } else if let rssImageUrl = feed.image?.url {
        if let imageUrl = URL(string: rssImageUrl, relativeTo: feedUrl) {
          storeImage(imageUrl)
        }
      }
    }

    self.lastParsed = Date()

    var newEpisodes = [Episode]()

    for item in feed.items ?? [] {
      guard let title = item.title else { continue }
      guard let guid = item.guid?.value else { continue }

      if let exists = self.episodes.first(where: { (e) -> Bool in
        return e.guid == guid || e.title == title
      }) {
        // Episode already exists as `exists`
        exists.parse(feedItem: item)
      } else {
        let episode = Episode(title: title, guid: guid)
        episode.parse(feedItem: item)
        episode.podcast = self
        episode.podcastId = self.id

        self.episodes.append(episode)
        newEpisodes.append(episode)
      }
    }

    return newEpisodes
  }

  func fetch() -> [Episode] {
    guard let feed = self.feed else { return [] }
    guard let feedUrl = URL(string: feed) else { return [] }

    let parser = FeedParser(URL: feedUrl)

    let result = parser.parse()

    switch result {
    case .success(let feed):
      guard let rssFeed = feed.rssFeed else { return [] }
      return self.parse(feed: rssFeed)
    case .failure(let error):
      Library.log(level: .error, "Error reloading \(self.title): \(String(describing: error.localizedDescription))")
      return []
    }
  }

  static func subscribe(feedUrl: URL) -> Podcast? {
    let parser = FeedParser(URL: feedUrl)
    let result = parser.parse()

    switch result {
    case .success(let feed):
      guard let rssFeed = feed.rssFeed else { return nil }
      guard let title = rssFeed.title else { return nil }

      let podcast = Podcast(title: title)
      podcast.feed = feedUrl.absoluteString
      let _ = podcast.parse(feed: rssFeed)

      return podcast
    case .failure(let error):
      NSApplication.shared.presentError(error)
      return nil
    }
  }

  // Detect either an iTunes podcast or RSS feed and call completion with resulting podcast
  static func detect(url: String, completion: @escaping (_ result: Podcast?) -> Void) -> Bool {
    if url.contains("itunes.apple.com") || url.contains("podcasts.apple.com") {
      return Utils.iTunesFeedUrl(iTunesUrl: url, completion: { (feedUrl) in
        guard let feedUrl = URL(string: feedUrl ?? "") else {
          return
        }

        DispatchQueue.main.async {
          completion(Podcast.subscribe(feedUrl: feedUrl))
        }
      })
    } else {
      guard let url = URL(string: url) else {
        return false
      }

      DispatchQueue.main.async {
        completion(Podcast.subscribe(feedUrl: url))
      }

      return true
    }
  }

}
