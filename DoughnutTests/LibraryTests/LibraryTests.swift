//
//  LibraryTests.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest
import Doughnut

class LibraryTests: BaseTestCase {
  func testSubscribe() {
    Library.global.connect()
    let sub = Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    
    XCTAssertEqual(sub, "Test Feed")
  }
}
