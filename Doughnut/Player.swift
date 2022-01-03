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

import AVFoundation
import Cocoa

protocol PlayerDelegate: AnyObject {
  func update(forEpisode episode: Episode)
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
  var currentEpisode: Episode?

  var volume: Float = 0.6 { //UserDefaults.standard.float(forKey: Preference.kVolume) {
    didSet {
      avPlayer?.volume = volume
      UserDefaults.standard.set(volume, forKey: Preference.kVolume)
    }
  }

  var isPlaying: Bool {
    get {
      guard let av = avPlayer else { return false }
      return av.rate != 0 && av.error == nil
    }
  }

  var canPlay: Bool {
    get {
      guard let av = avPlayer else { return false }
      return av.error == nil
    }
  }

  var position: Double = 0
  var buffered: Double = 0
  var duration: Double = 0

  let playedThreshold: Double = 0.9

  var pausedAt: TimeInterval? = nil

  func play(episode: Episode) {
    guard episode.podcast != nil else { return }

    // Destroy any existing player
    if let avPlayer = avPlayer {
      if let existing = currentEpisode, existing.id == episode.id {
        // This episode is already playing so just ignore and abort play()
        return
      }

      // Destroy the existing player and let a new one be created
      avPlayer.pause()
      self.avPlayer = nil
    }

    if episode.downloaded {
      guard let episodeUrl = episode.url() else { return }

      avPlayer = AVPlayer(url: episodeUrl)
    } else {
      guard let enclosureUrl = episode.enclosureUrl else { return }
      guard let url = URL(string: enclosureUrl) else { return }

      avPlayer = AVPlayer(url: url)
    }

    if let avPlayer = avPlayer, let episodeId = episode.id {
      // Register to receive timing events
      avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { time in
        self.position = time.seconds
        self.duration = avPlayer.currentItem?.asset.duration.seconds ?? 0

        if let bufferedRange = avPlayer.currentItem?.loadedTimeRanges.first {
          self.buffered = CMTimeRangeGetEnd(bufferedRange.timeRangeValue).seconds
        }

        self.delegate?.updatePlayback()
      })

      // Update episode with playback state
      avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { time in
        if let episode = Library.global.episode(id: episodeId) {
          episode.playPosition = Int(time.seconds)
          episode.duration = Int(avPlayer.currentItem?.asset.duration.seconds ?? 0)

          if episode.duration > 0 && (Double(episode.playPosition) / Double(episode.duration)) > self.playedThreshold {
            episode.played = true
          }

          Library.global.save(episode: episode)
        }
      })

      // Register to receive status events
      avPlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)

      // Extract any useful metadata from the audio file
      let metadata = avPlayer.currentItem?.asset.metadata ?? []
      for item in metadata {
        if item.commonKey == nil { continue }

        if let key = item.commonKey, let value = item.value {
          if key.rawValue == "artwork" {
            episode.artwork = NSImage(data: value as! Data)
          }
        }
      }

      avPlayer.currentItem?.preferredForwardBufferDuration = CMTimeGetSeconds(CMTime(seconds: 120, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))

      // Reset state
      self.duration = 0
      self.buffered = 0
      self.position = 0
      self.pausedAt = nil
      delegate?.updatePlayback()

      // Seek to existing position
      if episode.playPosition > 0 {
        avPlayer.seek(to: CMTime(seconds: Double(episode.playPosition), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
      }

      avPlayer.volume = volume
      delegate?.update(forEpisode: episode)
      currentEpisode = episode
      avPlayer.play()
    }
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
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

        print("Playing")
        delegate?.updatePlayback()
      }
    }
  }

  func togglePlay() {
    if isPlaying {
      pause()
    } else {
      play()
    }
  }

  func play() {
    guard let av = avPlayer else { return }

    if Preference.bool(for: Preference.Key.replayAfterPause) {
      // Only replay if paused more than 1 minute ago
      if let pausedAt = pausedAt {
        if (Date().timeIntervalSince1970 - pausedAt) >= 60 {
          skipBack()
        }
      }
    }

    av.play()
  }

  func pause() {
    guard let av = avPlayer else { return }
    av.pause()

    pausedAt = Date().timeIntervalSince1970
  }

  func skipAhead() {
    guard let av = avPlayer else { return }
    guard let duration = av.currentItem?.duration else { return }

    let currentTime = CMTimeGetSeconds(av.currentTime())
    let skipDuration = Preference.double(for: Preference.Key.skipForwardDuration)
    let targetTime = currentTime + skipDuration

    if targetTime < (CMTimeGetSeconds(duration) - skipDuration) {
      av.seek(to: CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }
  }

  func skipBack() {
    guard let av = avPlayer else { return }

    let currentTime = CMTimeGetSeconds(av.currentTime())
    var targetTime = currentTime - Preference.double(for: Preference.Key.skipBackDuration)

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
      let error = NSError(domain: NSOSStatusErrorDomain, code: Int(errorCode), userInfo: [NSLocalizedDescriptionKey: "CAError: \(errorCode)" ])
      NSApplication.shared.presentError(error)
      throw error
    }
  }
}
