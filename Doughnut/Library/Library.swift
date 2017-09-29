//
//  Library.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation
import FeedKit
import GRDB

class Library: NSObject {
  static var global = Library()
  static let databaseFilename = "Doughnut Library.dnl"
  
  let path: URL
  var dbQueue: DatabaseQueue?
  
  override init() {
    // Look for libaryPath stoed as in prefs
    if let prefPath = Preference.libraryPath() {
      if FileManager.default.fileExists(atPath: Library.databaseFile(inPath: prefPath).path) {
        self.path = prefPath
      } else {
        // A previous library was created that we can't access, prompt the user
        if let path = Library.locate() {
          self.path = path
        } else {
          fatalError("No library located!")
        }
      }
    } else {
      self.path = Preference.defaultLibraryPath()
    }
  }
  
  func connect() -> Bool {
    do {
      dbQueue = try DatabaseQueue(path: databaseFile().path)
      
      if let dbQueue = dbQueue {
        try LibraryMigrations.migrate(db: dbQueue)
        print("Connected to Doughnut library at \(path.path)")
        return true
      } else {
        return false
      }
    } catch {
      print("Failed to connect to \(databaseFile().path)")
      return false
    }
  }
  
  private func databaseFile() -> URL {
    return self.path.appendingPathComponent(Library.databaseFilename)
  }
  
  static private func databaseFile(inPath: URL) -> URL {
    return inPath.appendingPathComponent(Library.databaseFilename)
  }
  
  static private func locate() -> URL? {
    let alert = NSAlert()
    alert.addButton(withTitle: "Locate Library")
    alert.addButton(withTitle: "New Library")
    alert.addButton(withTitle: "Quit")
    alert.messageText = "Doughnut Library Not Found"
    alert.informativeText = "Your Doughnut library could not be found. If you have an existing library, choose to locate it or create a blank new podcast library."
    
    let result = alert.runModal()
    if result == .alertFirstButtonReturn {
      let panel = NSOpenPanel()
      panel.canChooseFiles = false
      panel.canChooseDirectories = true
      
      panel.runModal()
      return panel.url
    } else if result == .alertSecondButtonReturn {
      return Preference.defaultLibraryPath()
    } else {
      return nil
    }
  }
  
  //
  // General library methods
  
  func subscribe(url: String) -> Podcast? {
    guard let dbQueue = self.dbQueue else { return nil }
    guard let feedUrl = URL(string: url) else { return nil }
    
    if let parser = FeedParser(URL: feedUrl) {
      let result = parser.parse()
      
      if result.isFailure {
        print(result.error as Any)
      } else {
        if let feed = result.rssFeed {
          guard let podcast = Podcast.parse(response: feed) else { return nil }
          
          podcast.feed = feedUrl.absoluteString
          
          do {
            try dbQueue.inDatabase { db in
              try podcast.insert(db)
            }
            
            return podcast
            
          } catch let error as DatabaseError {
            print(error.message as Any)
            return nil
          } catch {
          }
          
        } else {
          let alert = NSAlert()
          alert.messageText = "Invalid Feed"
          alert.informativeText = "The response was not a valid RSS feed"
          alert.runModal()
        }
      }
    }
    
    return nil
  }
  
  func unsubscribe(podcast: Podcast) {
    
  }
  
  func podcast(id: Int64) -> Podcast? {
    guard let dbQueue = dbQueue else { return nil }
    
    do {
      return try dbQueue.inDatabase { db -> Podcast? in
        return try Podcast.fetchOne(db, key: id)
      }
    } catch {}
    
    return nil
  }
  
  func reload() {
    
  }
}
