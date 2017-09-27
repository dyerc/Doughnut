//
//  Library.swift
//  Doughnut
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation
import FeedKit

class Library: NSObject {
  static var global = Library()
  
  func subscribe(url: String) {
    guard let feedUrl = URL(string: url) else { return }
    
    if let parser = FeedParser(URL: feedUrl) {
      let result = parser.parse()
      
      if result.isFailure {
        print(result.error as Any)
      } else {
        if let feed = result.rssFeed {
          parseFeed(feed: feed)
        }
      }
    }
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
