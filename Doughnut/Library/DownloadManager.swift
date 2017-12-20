/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 Chris Dyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import AVFoundation

protocol DownloadManagerDelegate {
  func downloadStarted()
  func downloadFinished()
}

protocol DownloadTaskDelegate {
  func download(didComplete download: DownloadTask)
  func download(didError download: DownloadTask)
}

protocol DownloadProgressDelegate {
  func download(progressed download: DownloadTask)
}

class DownloadTask: NSObject, URLSessionDownloadDelegate {
  let downloadManager: DownloadManager
  let episode: Episode
  let podcast: Podcast
  var task: URLSessionDownloadTask?
  
  var delegate: DownloadTaskDelegate?
  var progressDelegate: DownloadProgressDelegate?
  
  var progressedBytes: Double = 0
  var totalBytes: Double = 0
  
  var waiting: Bool {
    get {
      return task?.state != .running
    }
  }
  
  init(manager: DownloadManager, episode: Episode, podcast: Podcast) {
    self.downloadManager = manager
    self.episode = episode
    self.podcast = podcast
    
    super.init()
    
    let session = URLSession(configuration: manager.sessionConfiguration, delegate: self, delegateQueue: nil)
    
    if let enclosureUrl = episode.enclosureUrl {
      if let url = URL(string: enclosureUrl) {
        task = session.downloadTask(with: url)
      }
    }
  }
  
  func resume() {
    task?.resume()
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let storagePath = podcast.storagePath() else {
      print("Could not determine podcast storage location")
      delegate?.download(didError: self)
      return
    }
    
    let fileName = episode.file()
    let outputPath = storagePath.appendingPathComponent(fileName)
    
    do {
      try FileManager.default.copyItem(at: location, to: outputPath)
      
      let avAsset = AVAsset(url: outputPath)
      
      episode.duration = Int(exactly: avAsset.duration.seconds) ?? 0
      episode.downloaded = true
      episode.fileName = fileName
      delegate?.download(didComplete: self)
      
    } catch {
      print("Failed to move downloaded file into position from \(location.path) to \(outputPath.path)")
      delegate?.download(didError: self)
    }
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
    
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    progressedBytes = Double(totalBytesWritten)
    totalBytes = Double(totalBytesExpectedToWrite)
    
    DispatchQueue.main.async {
      self.progressDelegate?.download(progressed: self)
    }
  }
}

class DownloadManager: NSObject, DownloadTaskDelegate {
  let sessionConfiguration = URLSessionConfiguration.default
  var downloads = [DownloadTask]()
  
  var delegate: DownloadManagerDelegate?
  
  var queueCount: Int {
    get {
      return downloads.count
    }
  }
  
  func queueDownload(episode: Episode) {
    guard let podcast = episode.podcast else {
      print("Cannot queue download, no parent podcast is present")
      return
    }
    
    let dl = DownloadTask(manager: self, episode: episode, podcast: podcast)
    dl.delegate = self
    
    downloads.append(dl)
    
    if (downloads.count == 1) {
      dl.resume()
    }
    
    delegate?.downloadStarted()
  }
  
  func download(didComplete download: DownloadTask) {
    let episode = download.episode
    Library.global.save(episode: episode)
    
    if let index = downloads.index(of: download) {
      downloads.remove(at: index)
    }
    
    delegate?.downloadFinished()
  }
  
  func download(didError download: DownloadTask) {
    print("Download failed")
    
    if let index = downloads.index(of: download) {
      downloads.remove(at: index)
    }
    
    delegate?.downloadFinished()
  }
}
