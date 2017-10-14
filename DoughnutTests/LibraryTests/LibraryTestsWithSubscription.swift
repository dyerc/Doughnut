//
//  LibraryTestsWithSubscription.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 13/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest
import Doughnut
import GRDB

class LibraryTestsWithSubscription: LibraryTestCase {
  var library: Library?
  var sub: Podcast?
  
  override func setUp() {
    super.setUp()
    
    // Setup an initial podcast subscription
    let expectation = self.expectation(description: "Library has subscribed")
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.subscribedToPodcastExpectation = expectation
    
    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    self.waitForExpectations(timeout: 10) { error in
      self.sub = spy.subscribedToPodcastResult
    }
  }
  
  func testReloadWhenNoNewEpisodesExist() {
    XCTAssertEqual(sub!.episodes.count, 2)
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.updatedPodcastExpectation = self.expectation(description: "Library updated podcast")
    
    Library.global.reload(podcast: sub!)
    
    self.waitForExpectations(timeout: 10) { error in
      guard let podcast = spy.updatedPodcastResult else {
        XCTFail("Expected delegate to be called")
        return
      }
      
      XCTAssertEqual(podcast.episodes.count, 2)
    }
  }
  
  func testReloadWhenNewEpisodesExist() {
    XCTAssertEqual(sub!.episodes.count, 2)
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.updatedPodcastExpectation = self.expectation(description: "Library updated podcast")
    
    // Silently change podcast feed
    sub!.feed = fixtureURL("ValidFeedx3", type: "xml").absoluteString
    do {
      try Library.global.dbQueue?.inDatabase { db in
        try sub!.save(db)
      }
    } catch {}
    
    Library.global.reload(podcast: sub!)
    
    self.waitForExpectations(timeout: 10) { error in
      guard let podcast = spy.updatedPodcastResult else {
        XCTFail("Expected delegate to be called")
        return
      }
      
      XCTAssertEqual(podcast.episodes.count, 3)
      
      // Ensure new episodes are linked back to podcast
      do {
        try Library.global.dbQueue?.inDatabase({ db in
          try XCTAssertEqual(Episode.filter(Column("podcast_id") == podcast.id).fetchCount(db), 3)
        })
      } catch {
        XCTFail()
      }
    }
  }
  
  func testReloadUpdatesExistingEpisodes() {
    XCTAssertEqual(sub!.episodes.count, 2)
    sub!.feed = fixtureURL("ValidFeedx3", type: "xml").absoluteString
    Library.global.save(podcast: sub!)
    
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.updatedPodcastExpectation = self.expectation(description: "Library updated podcast")
    
    Library.global.reload(podcast: sub!)
    
    self.waitForExpectations(timeout: 10) { error in
      guard let podcast = spy.updatedPodcastResult else {
        XCTFail("Expected delegate to be called")
        return
      }
      
      var episodeTitleUpdated = false
      for e in podcast.episodes {
        if e.title == "Test Podcast Episode #2 Edited" {
          episodeTitleUpdated = true
        }
      }
      
      XCTAssert(episodeTitleUpdated)
    }
  }
  
  func testSavePodcast() {
    
  }
  
  func testSaveEpisode() {
    
  }
}

