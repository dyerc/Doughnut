//
//  DownloadTask.swift
//  Doughnut
//
//  Created by Chris Dyer on 02/01/2018.
//  Copyright © 2018 Chris Dyer. All rights reserved.
//

import AVFoundation
import Foundation

class EpisodeDownloadTask: Task, URLSessionDownloadDelegate {
  let sessionConfiguration = URLSessionConfiguration.default
  let episode: Episode
  let podcast: Podcast

  var urlSessionTask: URLSessionDownloadTask?
  let byteFormatter = ByteCountFormatter()

  init(episode: Episode, podcast: Podcast) {
    self.episode = episode
    self.podcast = podcast

    super.init(name: episode.title)

    byteFormatter.allowedUnits = .useMB
    byteFormatter.countStyle = .file

    self.success = { object in
      let episode = object as! Episode
      Library.global.save(episode: episode)
    }

    let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)

    if let enclosureUrl = episode.enclosureUrl {
      if let url = URL(string: enclosureUrl) {
        urlSessionTask = session.downloadTask(with: url)
      }
    }
  }

  var complete: ((Bool, Any?) -> Void)? = nil

  override func perform(queue: DispatchQueue, completion: @escaping (Bool, Any?) -> Void) {
    if let task = urlSessionTask {
      complete = completion
      task.resume()
    } else {
      completion(false, "Invalid episode object")
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let completion = complete else { return }

    guard let storagePath = podcast.storagePath() else {
      completion(false, "Could not determine podcast storage location")
      return
    }

    let fileName = episode.file()
    let outputPath = storagePath.appendingPathComponent(fileName)

    isIndeterminate = true
    detailInformation = "Copying to library"
    emitProgress()

    do {
      try FileManager.default.copyItem(at: location, to: outputPath)

      let avAsset = AVAsset(url: outputPath)

      episode.duration = Int(exactly: avAsset.duration.seconds) ?? 0
      episode.downloaded = true
      episode.downloading = false
      episode.fileName = fileName

      Library.global.save(episode: episode)

      completion(true, episode)

    } catch {
      completion(false, "Failed to move downloaded file into position from \(location.path) to \(outputPath.path)")
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    progressValue = Double(totalBytesWritten)
    progressMax = Double(totalBytesExpectedToWrite)
    detailInformation = "\(byteFormatter.string(fromByteCount: Int64(progressValue))) of \(byteFormatter.string(fromByteCount: Int64(progressMax)))"
    isIndeterminate = false

    emitProgress()
  }
}
