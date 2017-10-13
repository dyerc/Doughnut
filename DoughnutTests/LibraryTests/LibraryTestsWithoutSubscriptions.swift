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

class LibraryTestsWithoutSubscription: LibraryTestCase {
  var library: Library?
  
  func testSubscribe() {
    let expectation = self.expectation(description: "Library calls didSubscribeToPodcast")
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.subscribedToPodcastExpectation = expectation
    
    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    
    self.waitForExpectations(timeout: 1) { error in
      if let error = error {
        XCTFail("\(error)")
      }
      
      guard let sub = spy.subscribedToPodcastResult else {
        XCTFail("Expected delegate to be called")
        return
      }
      
      XCTAssertEqual(sub.title, "Test Feed")
      XCTAssertEqual(sub.author, "CD1212")
      XCTAssertGreaterThan(sub.id!, 0)
      XCTAssertEqual(sub.episodes.count, 2)
      
      let pod = Library.global.podcast(id: sub.id!)
      XCTAssertEqual(pod!.title, sub.title)
    }
  }
}
