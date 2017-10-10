//
//  Player.swift
//  Doughnut
//
//  Created by Chris Dyer on 01/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa
import AVFoundation

protocol PlayerDelegate: class {
  func updateForEpisode(episode: Episode)
  func updatePlayback()
}

enum PlayerLoadStatus {
  case playing
  case none
  case loading
}

class Player: NSObject {
  static var global = Player()
  
  weak var delegate: PlayerDelegate?
  
  var loadStatus: PlayerLoadStatus = .none
  var avPlayer: AVPlayer?
  
  var volume: Float = 0.6 { //UserDefaults.standard.float(forKey: Preference.kVolume) {
    didSet {
      avPlayer?.volume = volume
      UserDefaults.standard.set(volume, forKey: Preference.kVolume)
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
        
        self.delegate?.updatePlayback()
      })
      
      avPlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
      
      self.duration = 0
      self.buffered = 0
      self.position = 0
      delegate?.updatePlayback()
      
      avPlayer.volume = volume
      delegate?.updateForEpisode(episode: episode)
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
        
        delegate?.updatePlayback()
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
  
  static func audioOutputDevices() throws -> [AudioDeviceID] {
    var inputDevices: [AudioDeviceID] = []
    
    // Construct the address of the property which holds all available devices
    var devicesPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
    var propertySize = UInt32(0)
    
    try handleCoreAudio(AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devicesPropertyAddress, 0, nil, &propertySize))
    
    // Get the number of devices by dividing the property address by the size of AudioDeviceIDs
    let numberOfDevices = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
    
    // Create space to store the values
    var deviceIDs: [AudioDeviceID] = []
    for _ in 0 ..< numberOfDevices {
      deviceIDs.append(AudioDeviceID())
    }
    
    // Get the available devices
    try handleCoreAudio(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devicesPropertyAddress, 0, nil, &propertySize, &deviceIDs))
    
    // Iterate
    for id in deviceIDs {
      
      // Get the device name for fun
      var name: CFString = "" as CFString
      var propertySize = UInt32(MemoryLayout<CFString>.size)
      var deviceNamePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
      try handleCoreAudio(AudioObjectGetPropertyData(id, &deviceNamePropertyAddress, 0, nil, &propertySize, &name))
      
      // Check the input scope of the device for any channels. That would mean it's an input device
      
      // Get the stream configuration of the device. It's a list of audio buffers.
      var streamConfigAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: kAudioDevicePropertyScopeInput, mElement: 0)
      
      // Get the size so we can make room again
      try handleCoreAudio(AudioObjectGetPropertyDataSize(id, &streamConfigAddress, 0, nil, &propertySize))
      
      // Create a buffer list with the property size we just got and let core audio fill it
      let audioBufferList = AudioBufferList.allocate(maximumBuffers: Int(propertySize))
      try handleCoreAudio(AudioObjectGetPropertyData(id, &streamConfigAddress, 0, nil, &propertySize, audioBufferList.unsafeMutablePointer))
      
      // Get the number of channels in all the audio buffers in the audio buffer list
      var channelCount = 0
      for i in 0 ..< Int(audioBufferList.unsafeMutablePointer.pointee.mNumberBuffers) {
        channelCount = channelCount + Int(audioBufferList[i].mNumberChannels)
      }
      
      free(audioBufferList.unsafeMutablePointer)
      
      // If there are channels, it's an input device
      
      Swift.print("Found output device '\(name)' with \(channelCount) channels [\(id)]")
      inputDevices.append(id)
    }
    
    return inputDevices
  }
  
  static func handleCoreAudio(_ errorCode: OSStatus) throws {
    if errorCode != kAudioHardwareNoError {
      let error = NSError(domain: NSOSStatusErrorDomain, code: Int(errorCode), userInfo: [NSLocalizedDescriptionKey : "CAError: \(errorCode)" ])
      NSApplication.shared.presentError(error)
      throw error
    }
  }
}
