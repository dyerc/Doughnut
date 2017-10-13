//
//  BaseTestCase.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest

class LibraryTestCase: XCTestCase {
  func fixtureURL(_ name: String, type: String) -> URL {
    let bundle = Bundle(for: Swift.type(of: self))
    let filePath = bundle.path(forResource: name, ofType: type)
    return URL(fileURLWithPath: filePath!)
  }
  
  override func setUp() {
    super.setUp()
    
    if !Preference.testEnv() {
      fatalError("Not running in test mode")
    }
    
    XCTAssertEqual(Library.global.connect(), true)
    print("Using library at \(Library.global.path)")
  }
  
  override func tearDown() {
    super.tearDown()
    
    do {
      try Library.global.dbQueue?.inDatabase({ db in
        try Podcast.deleteAll(db)
        try Episode.deleteAll(db)
      })
    } catch let error as NSError {
      fatalError("Failed to remove database \(error.debugDescription)")
    }
  }
}
