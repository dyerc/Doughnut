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
  var image: NSImage?
  var imageUrl: String?
  var lastParsed: Date?
  var subscribedAt: Date
  
  //var episodes = [Episode]()
  
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
    
    let imageData: DatabaseValue = row["image"]
    if !imageData.isNull {
      image = NSImage(data: row["image"])
    }
    
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
    container["image"] = compressImage()
    container["image_url"] = imageUrl
    container["last_parsed"] = lastParsed
    container["subscribed_at"] = subscribedAt
  }
  
  override func didInsert(with rowID: Int64, for column: String?) {
    id = rowID
  }
  
  func storeImage(_ url: URL) {
    imageUrl = url.absoluteString
    
    if let downloaded = NSImage(contentsOf: url) {
      image = Podcast.resizeArtwork(image: downloaded, w: 1024, h: 1024)
    }
  }
  
  func compressImage() -> Data? {
    guard let image = image else { return nil }
    guard let tiffData = image.tiffRepresentation else { return nil }
    guard let imageRep = NSBitmapImageRep(data: tiffData) else { return nil }
    return imageRep.representation(using: .jpeg, properties: [:])
  }
  
  static func parse(feedUrl: URL, response: RSSFeed) -> Podcast? {
    if let title = response.title {
      let podcast = Podcast(title: title)
      podcast.feed = feedUrl.absoluteString
      podcast.description = response.description
      podcast.link = response.link
      podcast.author = response.iTunes?.iTunesAuthor
      podcast.language = response.language
      podcast.copyright = response.copyright
      podcast.pubDate = response.pubDate
      
      // Prioritize iTunes image url over regular RSS
      if let iTunesImageUrl = response.iTunes?.iTunesImage?.attributes?.href {
        if let imageUrl = URL(string: iTunesImageUrl, relativeTo: feedUrl) {
          podcast.storeImage(imageUrl)
        }
      } else if let rssImageUrl = response.image?.url {
        if let imageUrl = URL(string: rssImageUrl, relativeTo: feedUrl) {
          podcast.storeImage(imageUrl)
        }
      }
      
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
  
  static func resizeArtwork(image: NSImage, w: Int, h: Int) -> NSImage {
    let destSize = NSMakeSize(CGFloat(w), CGFloat(h))
    let newImage = NSImage(size: destSize)
    newImage.lockFocus()
    image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
    newImage.unlockFocus()
    newImage.size = destSize
    return NSImage(data: newImage.tiffRepresentation!)!
  }
}
