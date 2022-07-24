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
import OSLog

import FeedKit
import GRDB

#if DEBUG
  let INITIAL_RELOAD_WAIT: TimeInterval = 60.0
#else
  let INITIAL_RELOAD_WAIT: TimeInterval = 10.0
#endif

protocol LibraryDelegate {
  func librarySubscribedToPodcast(subscribed: Podcast)
  func libraryUnsubscribedFromPodcast(unsubscribed: Podcast)
  func libraryUpdatingPodcasts(podcasts: [Podcast])
  func libraryUpdatedPodcasts(podcasts: [Podcast])
  func libraryUpdatedEpisodes(episodes: [Episode])
  func libraryReloaded()
}

enum LibraryError: Error {
  case databaseError(_: DatabaseError)
  case unknown(_: Error)
}

class Library: NSObject {
  static var global = Library()
  static let databaseFilename = "Doughnut Library.dnl"

  static let log = OSLog.main(category: "Library")

  enum Events: String {
    case Subscribed
    case Unsubscribed
    case Loaded
    case Reloaded
    case PodcastUpdated
    case Downloading

    var notification: Notification.Name {
      return Notification.Name(rawValue: self.rawValue)
    }
  }

  let path: URL
  var dbQueue: DatabaseQueue?
  var delegate: LibraryDelegate?
  let taskQueue = DispatchQueue(label: "com.doughnut.Library")
  let backgroundQueue = DispatchQueue(label: "com.doughnut.Background")

  let tasks = TaskQueue()

  var podcasts = [Podcast]()

  var unplayedCount: Int {
    get {
      return podcasts.reduce(0) {
        $0 + $1.unplayedCount
      }
    }
  }

  var minutesSinceLastScheduledReload = 0

  override init() {
    let libraryPath = Preference.libraryPath()

    var isDir = ObjCBool(true)
    if FileManager.default.fileExists(atPath: libraryPath.path, isDirectory: &isDir) {
      self.path = libraryPath
    } else {
      self.path = Library.locate()
    }
  }

  func connect() -> Bool {
    do {
      var configuration = Configuration()
      if Preference.bool(for: Preference.Key.debugSQLTraceEnabled) {
        configuration.prepareDatabase { db in
          db.trace {
            // swiftlint:disable:next no_direct_standard_out_logs
            print($0)
          }
        }
      }
      dbQueue = try DatabaseQueue(path: databaseFile().path, configuration: configuration)

      if let dbQueue = dbQueue {
        try LibraryMigrations.migrate(db: dbQueue)

        if !Preference.testEnv() {
          Self.log(level: .info, "Connected to Doughnut library at \(path.path)")
        }

        try dbQueue.inDatabase({ db in
          podcasts = try Podcast.fetchAll(db)

          for podcast in podcasts {
            podcast.loadEpisodes(db: db)

            #if DEBUG
              Self.log(level: .debug, "Loading \(podcast.title) with \(podcast.episodes.count) episodes")
            #endif
          }

          delegate?.libraryReloaded()
        })

        // After an initial delay, schedule auto-reload
        Timer.scheduledTimer(withTimeInterval: INITIAL_RELOAD_WAIT, repeats: false) { _ in
          // Perform an initial reload
          for podcast in Library.global.podcasts {
            if !podcast.manualReload {
              self.reload(podcast: podcast)
            }
          }

          // Schedule following reloads
          Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Library.global.minutesSinceLastScheduledReload += 1
            Library.global.scheduledReload()
          }
        }

        return true
      } else {
        return false
      }
    } catch let error {
      let alert = NSAlert()
      alert.messageText = "Failed to connect to library"
      alert.informativeText = "\(databaseFile().path)\n\nError: \(error)"
      alert.runModal()
      return false
    }
  }

  func databaseFile() -> URL {
    return self.path.appendingPathComponent(Library.databaseFilename)
  }

  static private func databaseFile(inPath: URL) -> URL {
    return inPath.appendingPathComponent(Library.databaseFilename)
  }

  static private func locate() -> URL {
    let alert = NSAlert()
    alert.addButton(withTitle: "Locate Library")
    alert.addButton(withTitle: "Default Library")
    alert.addButton(withTitle: "Quit")
    alert.messageText = "Doughnut Library Not Found"
    alert.informativeText = "Your Doughnut library could not be found. If you have an existing library, choose to locate it or create a blank new podcast library in the default location."

    let result = alert.runModal()
    if result == .alertFirstButtonReturn {
      let panel = NSOpenPanel()
      panel.canChooseFiles = false
      panel.canChooseDirectories = true

      panel.runModal()
      if let url = panel.url {
        Preference.set(url, for: Preference.Key.libraryPath)
        return url
      } else {
        return Library.locate()
      }
    } else if result == .alertSecondButtonReturn {
      // Reset library preference to default
      Preference.set(Preference.defaultLibraryPath, for: Preference.Key.libraryPath)
      return Preference.defaultLibraryPath
    } else {
      exit(0)
    }
  }

  static func handleDatabaseError(_ error: Error) {
    Self.log(level: .error, "Library: error \(error), stack trace: \(Thread.callStackSymbols)")
  }

  static func sanitizePath(_ path: String) -> String {
    let illegal = CharacterSet(charactersIn: "/\\%:|\"<>")
    return path.components(separatedBy: illegal).joined(separator: "")
  }

  //
  // General library methods

  func detectedNewEpisodes(podcast: Podcast, episodes: [Episode]) {
    guard let firstEpisode = episodes.first else { return }

    let notification = NSUserNotification()
    notification.soundName = NSUserNotificationDefaultSoundName

    if let artwork = podcast.image {
      notification.contentImage = artwork
    }

    if episodes.count > 1 {
      notification.title = "New Episodes of \(podcast.title)"
      notification.informativeText = "\(firstEpisode.title) + \(episodes.count - 1) more"
    } else {
      notification.title = "New Episode of \(podcast.title)"
      notification.informativeText = firstEpisode.title
    }

    if podcast.autoDownload {
      if let latestEpisode = episodes.first {
        latestEpisode.download()
      }
    }

    NSUserNotificationCenter.default.deliver(notification)
  }

  // MARK: - Database Operations

  func subscribe(url: String) {
    guard let dbQueue = self.dbQueue else { return }
    guard let feedUrl = URL(string: url) else { return }

    taskQueue.async {
      do {
        // Check if the podcast is already subscribed to
        let existing = try dbQueue.inDatabase({ db -> Podcast? in
          return try Podcast.filter(Column("feed") == feedUrl.absoluteString).fetchOne(db)
        })

        if existing != nil {
          return
        }
      } catch {
        Library.handleDatabaseError(error)
        return
      }

      if let podcast = Podcast.subscribe(feedUrl: feedUrl) {
        self.insert(podcast: podcast) { result in
          guard case .success = result else { return }

          // Don't notify newly detected episodes for a new subscription, maybe change in future?
          // self.detectedNewEpisodes(podcast: podcast, episodes: podcast.episodes)

          DispatchQueue.main.async {
            self.podcasts.append(podcast)
            self.delegate?.librarySubscribedToPodcast(subscribed: podcast)
          }
        }
      }
    }
  }

  func subscribe(podcast: Podcast) {
    guard let dbQueue = self.dbQueue else { return }

    taskQueue.async {
      do {
        // Check if the podcast is already subscribed to
        let existing = try dbQueue.inDatabase({ db -> Podcast? in
          return try Podcast.filter(Column("feed") == podcast.feed).fetchOne(db)
        })

        if existing != nil {
          return
        }
      } catch {
        Library.handleDatabaseError(error)
        return
      }

      self.insert(podcast: podcast, completion: { result in
        guard case .success = result else { return }

        DispatchQueue.main.async {
          self.podcasts.append(podcast)
          self.delegate?.librarySubscribedToPodcast(subscribed: podcast)
        }
      })
    }
  }

  func unsubscribe(podcast: Podcast, removeFiles: Bool = false) {
    guard let storedIndex = podcasts.firstIndex(where: { p -> Bool in p.id == podcast.id }) else { return }

    podcasts.remove(at: storedIndex)
    self.delegate?.libraryReloaded()

    taskQueue.async {
      if removeFiles {
        if let storagePath = podcast.storagePath() {
          NSWorkspace.shared.recycle([storagePath], completionHandler: { (trashedFiles, error) in
            if let error = error {
              Self.log(level: .error, "Failed to move podcast data to trash: \(error.localizedDescription)")

              let alert = NSAlert()
              alert.messageText = "Failed to trash data"
              alert.informativeText = error.localizedDescription
            } else {
              Self.log(level: .info, "Moved podcast data stored at \(trashedFiles) to trash")
            }
          })
        }
      }

      do {
        _ = try self.dbQueue?.inDatabase { db in
          try podcast.delete(db)
        }

        DispatchQueue.main.async {
          self.delegate?.libraryUnsubscribedFromPodcast(unsubscribed: podcast)
        }
      } catch let error as DatabaseError {
        Library.handleDatabaseError(error)
      } catch {}
    }
  }

  func podcast(id: Int64) -> Podcast? {
    return podcasts.first { (podcast) -> Bool in
      podcast.id == id
    }
  }

  func episode(id: Int64) -> Episode? {
    for p in podcasts {
      for e in p.episodes {
        if e.id == id {
          return e
        }
      }
    }

    return nil
  }

  func scheduledReload() {
    let reloadFrequency = Preference.integer(for: Preference.Key.reloadFrequency)

    // Reload podcasts on custom schedules
    for podcast in podcasts {
      if !podcast.manualReload && !podcast.defaultReload {
        if (minutesSinceLastScheduledReload >= podcast.reloadFrequency) && (podcast.reloadFrequency % minutesSinceLastScheduledReload == 0) {
          reload(podcast: podcast, onQueue: backgroundQueue)
        }
      }
    }

    // Reload podcasts on the default schedule
    if (reloadFrequency != -1 && minutesSinceLastScheduledReload >= reloadFrequency) {
      for podcast in podcasts {
        if podcast.defaultReload {
          reload(podcast: podcast, onQueue: backgroundQueue)
        }
      }

      minutesSinceLastScheduledReload = 0
    }
  }

  func reloadAll() {
    for podcast in podcasts {
      reload(podcast: podcast)
    }
  }

  func reload(podcast: Podcast, onQueue: DispatchQueue? = nil) {
    let workerQueue = onQueue ?? taskQueue

    workerQueue.async {
      // Mark as loading
      podcast.loading = true
      DispatchQueue.main.async {
        self.delegate?.libraryUpdatingPodcasts(podcasts: [podcast])
      }

      let newEpisodes = podcast.fetch()
      podcast.loading = false

      self.update(podcast: podcast) { [weak self] result in
        // TODO: error handling
        if case .success = result, newEpisodes.count > 0{
          DispatchQueue.main.async {
            self?.detectedNewEpisodes(podcast: podcast, episodes: newEpisodes)
          }
        }
      }
    }
  }

  func batchUpdateEpisodes(favourite: Bool, episodes: [Episode], completion: ((Result<[Episode], LibraryError>) -> Void)? = nil) {
    dbQueue?.asyncWrite({ db in
      let keys = episodes.compactMap { $0.id }
      try Episode.filter(keys: keys)
        .updateAll(db, Column("favourite").set(to: favourite))
    }, completion: { _, result in
      episodes.forEach {
        $0.favourite = favourite
      }

      switch result {
      case .success:
        DispatchQueue.main.async {
          self.delegate?.libraryUpdatedEpisodes(episodes: episodes)
        }
        completion?(.success(episodes))
      case let .failure(error):
        if let error = error as? DatabaseError {
          Library.handleDatabaseError(error)
          completion?(.failure(.databaseError(error)))
        } else {
          completion?(.failure(.unknown(error)))
        }
      }
    })
  }

  func batchUpdateEpisodes(played: Bool, episodes: [Episode], completion: ((Result<[Episode], LibraryError>) -> Void)? = nil) {
    dbQueue?.asyncWrite({ db in
      let keys = episodes.compactMap { $0.id }
      try Episode.filter(keys: keys)
        .updateAll(db, Column("played").set(to: played))
    }, completion: { _, result in
      episodes.forEach {
        $0.played = played
      }

      switch result {
      case .success:
        DispatchQueue.main.async {
          self.delegate?.libraryUpdatedEpisodes(episodes: episodes)
        }
        completion?(.success(episodes))
      case let .failure(error):
        if let error = error as? DatabaseError {
          Library.handleDatabaseError(error)
          completion?(.failure(.databaseError(error)))
        } else {
          completion?(.failure(.unknown(error)))
        }
      }
    })
  }

  // Async episode save and event emission
  func save(episode: Episode, completion: ((Result<Episode, LibraryError>) -> Void)? = nil) {
    dbQueue?.asyncWrite({ db in
      if episode.id != nil {
        try episode.updateChanges(db)
      } else {
        try episode.save(db)
      }
    }, completion: { _, result in
      switch result {
      case .success:
        completion?(.success(episode))
        DispatchQueue.main.async {
          self.delegate?.libraryUpdatedEpisodes(episodes: [episode])
        }
      case let .failure(error):
        if let error = error as? DatabaseError {
          Library.handleDatabaseError(error)
          completion?(.failure(.databaseError(error)))
        } else {
          completion?(.failure(.unknown(error)))
        }
      }
    })
  }

  func delete(episode: Episode, completion: ((Result<Episode, LibraryError>) -> Void)? = nil) {
    guard let podcast = episode.podcast else { return }

    dbQueue?.asyncWrite({ db in
      try episode.delete(db)
    }, completion: { _, result in
      switch result {
      case .success:
        completion?(.success(episode))
        DispatchQueue.main.async {
          self.delegate?.libraryUpdatedPodcasts(podcasts: [podcast])
        }
      case let .failure(error):
        if let error = error as? DatabaseError {
          Library.handleDatabaseError(error)
          completion?(.failure(.databaseError(error)))
        } else {
          completion?(.failure(.unknown(error)))
        }
      }
    })
  }

  // Async podcast insert
  func insert(podcast: Podcast, completion: ((Result<Podcast, LibraryError>) -> Void)? = nil) {
    dbQueue?.asyncWrite({ db in
      try podcast.insert(db)

      for episode in podcast.episodes {
        if episode.id != nil {
          try episode.updateChanges(db)
        } else {
          try episode.save(db)
        }
      }
    }, completion: { _, result in
      switch result {
      case .success:
        completion?(.success(podcast))
      case let .failure(error):
        if let error = error as? DatabaseError {
          Library.handleDatabaseError(error)
          completion?(.failure(.databaseError(error)))
        } else {
          completion?(.failure(.unknown(error)))
        }
      }
    })
  }

  // Async podcast update and event emission
  func update(podcast: Podcast, completion: ((Result<Podcast, LibraryError>) -> Void)? = nil) {
    dbQueue?.asyncWrite({ db in
      try podcast.updateChanges(db)

      for episode in podcast.episodes {
        if episode.id != nil {
          try episode.updateChanges(db)
        } else {
          try episode.save(db)
        }
      }
    }, completion: { _, result in
      switch result {
      case .success:
        completion?(.success(podcast))
        DispatchQueue.main.async {
          self.delegate?.libraryUpdatedPodcasts(podcasts: [podcast])
        }
      case let .failure(error):
        if let error = error as? DatabaseError {
          Library.handleDatabaseError(error)
          completion?(.failure(.databaseError(error)))
        } else {
          completion?(.failure(.unknown(error)))
        }
      }
    })
  }
}
