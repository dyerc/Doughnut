//
//  Podcast.swift
//  Doughnut
//
//  Created by Chris Dyer on 28/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation
import GRDB
import FeedKit

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
  var imageUrl: String?
  var lastParsed: Date?
  var subscribedAt: Date
  
  override class var databaseTableName: String {
    return "podcasts"
  }
  
  init(title: String) {
    self.title = title
    self.path = Podcast.sanitizePodcastPath(title)
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
    imageUrl = row["image_url"]
    lastParsed = row["last_parsed"]
    subscribedAt = row["subscribed_at"]
    
    super.init(row: row)
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
    container["image_url"] = imageUrl
    container["last_parsed"] = lastParsed
    container["subscribed_at"] = subscribedAt
  }
  
  override func didInsert(with rowID: Int64, for column: String?) {
    id = rowID
  }
  
  static func parse(response: RSSFeed) -> Podcast? {
    if let title = response.title {
      let podcast = Podcast(title: title)
      podcast.description = response.description
      podcast.link = response.link
      podcast.author = response.iTunes?.iTunesAuthor
      podcast.language = response.language
      podcast.copyright = response.copyright
      podcast.pubDate = response.pubDate
      podcast.imageUrl = response.image?.url
      
      podcast.lastParsed = Date()
      
      return podcast
    } else {
      return nil
    }
  }
  
  static func sanitizePodcastPath(_ path: String) -> String {
    let illegal = CharacterSet(charactersIn: "/\\%|\"<>")
    return path.components(separatedBy: illegal).joined(separator: "")
  }
}
