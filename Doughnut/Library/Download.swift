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
  let podcast: Podcast
  var task: URLSessionDownloadTask?
  var delegate: DownloadProgressDelegate?
  
  var progressedBytes: Double = 0
  var totalBytes: Double = 0
  
  init(episode: Episode, podcast: Podcast) {
    self.episode = episode
    self.podcast = podcast
    super.init()
    
    let sessionConfiguration = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    
    if let enclosureUrl = episode.enclosureUrl {
      if let url = URL(string: enclosureUrl) {
        task = session.downloadTask(with: url)
        task?.resume()
      }
    }
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    if let outputPath = podcast.storagePath(forEpisode: episode) {
      do {
        try FileManager.default.copyItem(at: location, to: outputPath)
      } catch {
        print("Failed to move downloaded file into position from \(location.path) to \(outputPath.path)")
      }
    }
  }
    
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
    
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    progressedBytes = Double(totalBytesWritten)
    totalBytes = Double(totalBytesExpectedToWrite)
    
    DispatchQueue.main.async {
      self.delegate?.downloadProgressed()
    }
  }
}
