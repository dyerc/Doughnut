//
//  BaseTestCase.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest

class BaseTestCase: XCTestCase {
  func fixtureURL(_ name: String, type: String) -> URL {
    let bundle = Bundle(for: Swift.type(of: self))
    let filePath = bundle.path(forResource: name, ofType: type)
    return URL(fileURLWithPath: filePath!)
  }
}
