//
//  DoughnutApp.swift
//  Doughnut
//
//  Created by Chris Dyer on 19/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

@objc(DoughnutApp)
class DoughnutApp: NSApplication {
  override init() {
    super.init()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func sendEvent(_ event: NSEvent) {
    let shouldHandleLocally = !SPMediaKeyTap.usesGlobalMediaKeyTap()
    
    if shouldHandleLocally && event.type == .systemDefined && Int32(event.subtype.rawValue) == SPSystemDefinedEventMediaKeys {
      if let delegate = self.delegate as? AppDelegate {
        delegate.mediaKeyTap(nil, receivedMediaKeyEvent: event)
      }
    }
    
    super.sendEvent(event)
  }
}
