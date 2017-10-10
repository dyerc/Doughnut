//
//  Download.swift
//  Doughnut
//
//  Created by Chris Dyer on 10/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation

class Download: NSObject, URLSessionDownloadDelegate {
  let session = URLSession(configuration: URLSessionConfiguration.default)
  var task: URLSessionDownloadTask?
  
  init(episode: Episode) {
    session.download
    
    if let enclosureUrl = episode.enclosureUrl {
      if let url = URL(string: enclosureUrl) {
        task = session.downloadTask(with: url)
      }
    }
    
    super.init()
  }
  
  
}
