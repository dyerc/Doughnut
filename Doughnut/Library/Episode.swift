//
//  Episode.swift
//  Doughnut
//
//  Created by Chris Dyer on 29/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation
import GRDB
import FeedKit

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
    
    print("Set title to \(title)")
    self.title = title
    self.guid = guid
    description = feedItem.description
    pubDate = feedItem.pubDate
    link = feedItem.link
    
    if let enclosure = feedItem.enclosure?.attributes {
      enclosureUrl = enclosure.url
      enclosureSize = enclosure.length
    }
  }
  
  
}
