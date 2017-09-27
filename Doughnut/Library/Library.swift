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
  var db: DatabaseQueue?
  
  func connect() -> Bool {
    do {
      db = try DatabaseQueue(path: databaseFile())
      
      if let db = db {
        try LibraryMigrations.migrate(db: db)
        return true
      } else {
        return false
      }
    } catch {
      return false
    }
  }
  
  private func databaseFile() -> String {
    return Preference.libraryPath().appendingPathComponent("Doughnut Library.dnl").absoluteString
  }
  
  func subscribe(url: String) -> String? {
    guard let feedUrl = URL(string: url) else { return nil }
    
    if let parser = FeedParser(URL: feedUrl) {
      let result = parser.parse()
      
      if result.isFailure {
        print(result.error as Any)
      } else {
        if let feed = result.rssFeed {
          // parseFeed(feed: feed)
          return feed.title
        }
      }
    }
    
    return nil
  }
  
  func reload() {
    
  }
  
  func parseFeed(feed: RSSFeed) {
    print(feed.title)
    print(feed.copyright)
    
    if let items = feed.items {
      print("Episodes \(items.count)")
      
      let first = feed.items?.first
      print(first?.enclosure?.attributes?.url)
    }
  }
}
