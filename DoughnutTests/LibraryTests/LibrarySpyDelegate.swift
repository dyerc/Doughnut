//
//  LibrarySpyDelegate.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 13/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest
import Doughnut

class LibrarySpyDelegate: LibraryDelegate {
  var subscribedToPodcastExpectation: XCTestExpectation?
  var subscribedToPodcastResult: Podcast?
  func librarySubscribedToPodcast(subscribed: Podcast) {
    guard let expectation = subscribedToPodcastExpectation else {
      XCTFail("Missing didSubscribeToPodcast XCTExpectation reference")
      return
    }
    
    self.subscribedToPodcastResult = subscribed
    expectation.fulfill()
  }
  
  func libraryReloaded() {
    
  }
  
  var updatedPodcastExpectation: XCTestExpectation?
  var updatedPodcastResult: Podcast?
  func libraryUpdatedPodcast(podcast: Podcast) {
    guard let expectation = updatedPodcastExpectation else {
      XCTFail("Missing didUpdatePodcast XCTExpectation reference")
      return
    }
    
    updatedPodcastResult = podcast
    expectation.fulfill()
  }
  
  func libraryUpdatedEpisode(episode: Episode) {
    
  }
  
  func libraryUnsubscribedFromPodcast(unsubscribed: Podcast) {
    
  }
}
