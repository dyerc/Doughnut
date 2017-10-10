//
//  LibraryTests.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest
import Doughnut
import GRDB

class LibraryTests: BaseTestCase {
  var library: Library?
  
  override func setUp() {
    super.setUp()
    // Check we are in test mode
    XCTAssert(Preference.testEnv())
    
    XCTAssertEqual(Library.global.connect(), true)
    print("Using library at \(Library.global.path)")
  }
  
  override func tearDown() {
    do {
      try Library.global.dbQueue?.inDatabase({ db in
        try Podcast.deleteAll(db)
        try Episode.deleteAll(db)
      })
    } catch let error as NSError {
      fatalError("Failed to remove database \(error.debugDescription)")
    }
  }
  
  func testSubscribe() {
    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    let sub = Library.global.podcasts.first
    
    XCTAssertEqual(sub!.title, "Test Feed")
    XCTAssertEqual(sub!.author, "CD1212")
    XCTAssertGreaterThan(sub!.id!, 0)
    
    XCTAssertEqual(sub!.episodes.count, 2)
    //XCTAssertEqual(sub!.episodes.first?.title, "Test Podcast Episode #2")
    //XCTAssertEqual(sub!.episodes.first?.enclosureUrl, fixtureURL("enclosure", type: "mp3").path)
    
    // Try querying it back
    let pod = Library.global.podcast(id: sub!.id!)
    XCTAssertEqual(pod!.title, sub!.title)
  }
  
  func testReloadWhenNoNewEpisodesExist() {
    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    let sub = Library.global.podcasts.first
    XCTAssertEqual(sub!.episodes.count, 2)
    
    Library.global.reload(podcast: sub!)
    XCTAssertEqual(sub!.episodes.count, 2)
  }
  
  func testReloadWhenNewEpisodesExist() {
    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    let sub = Library.global.podcasts.first
    XCTAssertEqual(sub!.episodes.count, 2)
    
    sub!.feed = fixtureURL("ValidFeedx3", type: "xml").absoluteString
    Library.global.save(podcast: sub!)
    
    Library.global.reload(podcast: sub!)
    XCTAssertEqual(sub!.episodes.count, 3)
    
    do {
      try Library.global.dbQueue?.inDatabase({ db in
        try XCTAssertEqual(Episode.filter(Column("podcast_id") == sub!.id).fetchCount(db), 3)
      })
    } catch {
      XCTFail()
    }
  }
  
  func testReloadUpdatesExistingEpisodes() {
    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    let sub = Library.global.podcasts.first
    XCTAssertEqual(sub!.episodes.count, 2)
    
    sub!.feed = fixtureURL("ValidFeedx3", type: "xml").absoluteString
    Library.global.save(podcast: sub!)
    
    Library.global.reload(podcast: sub!)
    XCTAssertEqual(sub!.episodes.count, 3)
    
    var containsEdited = false
    for e in sub!.episodes {
      if e.title == "Test Podcast Episode #2 Edited" {
        containsEdited = true
      }
    }
    XCTAssert(containsEdited)
  }
}
