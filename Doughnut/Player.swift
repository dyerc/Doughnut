//
//  Player.swift
//  Doughnut
//
//  Created by Chris Dyer on 01/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Foundation
import AVFoundation

enum PlayerLoadStatus {
  case playing
  case none
  case loading
}

class Player: NSObject {
  static var global = Player()
  
  enum Events:String {
    case StatusChange = "StatusChange"
    case TimeChange = "TimeChange"
    
    var notification: Notification.Name {
      return Notification.Name(rawValue: self.rawValue)
    }
  }
  
  var loadStatus: PlayerLoadStatus = .none
  var avPlayer: AVPlayer?
  
  var volume: Float = 0.6 { //UserDefaults.standard.float(forKey: Preference.kVolume) {
    didSet {
      avPlayer?.volume = volume
      UserDefaults.standard.set(volume, forKey: Preference.kVolume)
      NotificationCenter.default.post(name: Events.StatusChange.notification, object: nil)
    }
  }
  
  var position: Double = 0
  var buffered: Double = 0
  var duration: Double = 0
  
  var skipDuration: Double = 10.0
  
  func play(episode: Episode) {
    if episode.downloaded && episode.fileExists() {
      avPlayer = AVPlayer(url: episode.file()!)
    } else {
      guard let enclosureUrl = episode.enclosureUrl else { return }
      guard let url = URL(string: enclosureUrl) else { return }
      
      avPlayer = AVPlayer(url: url)
    }
    
    if let avPlayer = avPlayer {
      avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { time in
        self.position = time.seconds
        self.duration = avPlayer.currentItem?.asset.duration.seconds ?? 0
        
        if let bufferedRange = avPlayer.currentItem?.loadedTimeRanges.first {
          self.buffered = CMTimeRangeGetEnd(bufferedRange.timeRangeValue).seconds
        }
        
        NotificationCenter.default.post(name: Events.TimeChange.notification, object: nil)
      })
      
      avPlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
      
      self.duration = 0
      self.buffered = 0
      self.position = 0
      NotificationCenter.default.post(name: Events.TimeChange.notification, object: nil)
      
      avPlayer.volume = volume
      avPlayer.play()
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if object as? AVPlayer == avPlayer {
      if keyPath == "status" {
        switch avPlayer?.status {
        case .unknown?:
          loadStatus = .loading
        case .readyToPlay?:
          loadStatus = .playing
        default:
          loadStatus = .none
        }
        
        NotificationCenter.default.post(name: Events.StatusChange.notification, object: nil)
      }
    }
  }
  
  func play() {
    guard let av = avPlayer else { return }
    av.play()
  }
  
  func pause() {
    guard let av = avPlayer else { return }
    av.pause()
  }
  
  func isPlaying() -> Bool {
    guard let av = avPlayer else { return false }
    return (av.rate != 0) && (av.error == nil)
  }
  
  func canPlay() -> Bool {
    guard let av = avPlayer else { return false }
    return av.error != nil
  }
  
  func skipAhead() {
    guard let av = avPlayer else { return }
    guard let duration = av.currentItem?.duration else { return }
    
    let currentTime = CMTimeGetSeconds(av.currentTime())
    let targetTime = currentTime + skipDuration
    
    if targetTime < (CMTimeGetSeconds(duration) - skipDuration) {
      av.seek(to: CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }
  }
  
  func skipBack() {
    guard let av = avPlayer else { return }
    
    let currentTime = CMTimeGetSeconds(av.currentTime())
    var targetTime = currentTime - skipDuration
    
    if targetTime < 0 {
      targetTime = 0
    }
    
    av.seek(to: CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
  }
  
  func seek(seconds: Double) {
    guard let av = avPlayer else { return }
    av.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
  }
}
