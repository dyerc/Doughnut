//
//  Download.swift
//  Doughnut
//
//  Created by Chris Dyer on 10/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation

protocol DownloadProgressDelegate {
  func downloadProgressed()
}

class Download: NSObject, URLSessionDownloadDelegate {
  let episode: Episode
  var task: URLSessionDownloadTask?
  var delegate: DownloadProgressDelegate?
  
  init(episode: Episode) {
    self.episode = episode
    super.init()
    
    let sessionConfiguration = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    
    if let enclosureUrl = episode.enclosureUrl {
      if let url = URL(string: enclosureUrl) {
        task = session.downloadTask(with: url)
      }
    }
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    
  }
    
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
    
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    
  }
}
