/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 - 2022 Chris Dyer
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
import OSLog

protocol PlayerDelegate: AnyObject {
  func update(forEpisode episode: Episode?)
  func updatePlayback()
}

enum PlayerLoadStatus {
  case playing
  case none
  case loading
}

final class Player: NSObject {
  static var global = Player()

  static let log = OSLog.main(category: "Player")

  weak var delegate: PlayerDelegate?

  private(set) var loadStatus: PlayerLoadStatus = .none
  private(set) var avPlayer: AVPlayer?
  private(set) var currentEpisode: Episode?
  private(set) var currentAVAsset: AVAsset?
  private(set) var currentPlaybackURL: URL?

  private(set) var position: Double = 0
  private(set) var buffered: Double = 0
  private(set) var duration: Double = 0
  private(set) var isSeeking: Bool = false

  private(set) var pausedAt: TimeInterval? = nil

  var playedThreshold: Double {
    let prefPercentage = Preference.double(for: Preference.Key.markAsPlayedAfter)

    if prefPercentage <= 100, prefPercentage >= 50 {
      return prefPercentage / 100
    } else {
      return 1
    }
  }

  var volume: Float = 0.6 { //UserDefaults.standard.float(forKey: Preference.kVolume) {
    didSet {
      avPlayer?.volume = volume
      UserDefaults.standard.set(volume, forKey: Preference.kVolume)
    }
  }

  var isPlaying: Bool {
    guard let av = avPlayer else { return false }
    return av.rate != 0 && av.error == nil
  }

  var canPlay: Bool {
    guard let av = avPlayer else { return false }
    return av.error == nil
  }

  var nowPlayingEpisodeInfoDictionary = [String: Any]()

  private var periodicTimeObservers = [Any]()

  private let userAgent: String = buildUserAgent()

  override init() {
    super.init()
    setupRemoteCommands()
  }

  func play(episode: Episode) {
    guard episode.podcast != nil else { return }

    if let existing = currentEpisode, existing.id == episode.id, avPlayer != nil {
      // This episode is already playing so just ignore and abort play()
      play()
      return
    }

    destroyAVPlayerAndResetState()

    let avAsset: AVAsset

    if episode.downloaded {
      guard let episodeUrl = episode.url() else { return }

      currentPlaybackURL = episodeUrl
      avAsset = AVAsset(url: episodeUrl)
    } else {
      guard let enclosureUrl = episode.enclosureUrl else { return }
      guard let url = URL(string: enclosureUrl) else { return }

      currentPlaybackURL = url
      avAsset = AVURLAsset(
        url: url,
        options: [
          "AVURLAssetHTTPHeaderFieldsKey": buildAVPlayerHTTPHeaders(),
        ]
      )
    }

    currentAVAsset = avAsset
    loadStatus = .loading
    postPlaybackStatusUpdates()

    avAsset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
      DispatchQueue.main.async {
        guard let self = self, avAsset == self.currentAVAsset else { return }

        var error: NSError?
        let status = avAsset.statusOfValue(forKey: "playable", error: &error)

        let cleanupLoadStatusOnFail: () -> Void = {
          self.currentPlaybackURL = nil
          self.currentAVAsset = nil
          self.loadStatus = .none
          self.postPlaybackStatusUpdates()
        }

        switch status {
        case .loaded:
          self.onAssetLoadingFinished(avAsset: avAsset, episode: episode)
          return
        case .loading:
          assert(false, "'.loading' should not be returned in the completionHandler of loadValuesAsynchronously(forKeys:).")
          break
        default:
          Player.log(level: .error, "Failed to load the AVAsset failed with status: \(status), error: \(error?.localizedDescription ?? "nil")")
          break
        }
        cleanupLoadStatusOnFail()
      }
    }
  }

  private func onAssetLoadingFinished(avAsset: AVAsset, episode: Episode) {
    assert(avAsset == currentAVAsset)

    let item = AVPlayerItem(asset: avAsset)
    avPlayer = AVPlayer(playerItem: item)

    if let avPlayer = avPlayer, let episodeId = episode.id {
      var timeObserver: Any?

      // Register to receive timing events
      timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5), queue: .main) { [weak self] time in
        guard let self = self else { return }

        guard !self.isSeeking else { return }

        self.position = time.seconds
        self.duration = avPlayer.currentItem?.asset.duration.seconds ?? 0

        if let bufferedRange = avPlayer.currentItem?.loadedTimeRanges.first {
          self.buffered = CMTimeRangeGetEnd(bufferedRange.timeRangeValue).seconds
        }

        self.postPlaybackStatusUpdates()
      }
      periodicTimeObservers.append(timeObserver!)

      // Update episode with playback state
      timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 5), queue: .main) { time in
        if let episode = Library.global.episode(id: episodeId) {
          episode.playPosition = Int(time.seconds)
          episode.duration = Int(avPlayer.currentItem?.asset.duration.seconds ?? 0)

          if episode.duration > 0, (Double(episode.playPosition) / Double(episode.duration)) >= self.playedThreshold {
            episode.played = true
          }

          Library.global.save(episode: episode)
        }
      }
      periodicTimeObservers.append(timeObserver!)

      // Register to receive status events
      avPlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)

      // Extract any useful metadata from the audio file
      let metadata = avPlayer.currentItem?.asset.metadata ?? []
      for item in metadata {
        if item.commonKey == nil { continue }

        if let key = item.commonKey, let value = item.value {
          if key == .commonKeyArtwork {
            episode.artwork = NSImage(data: value as! Data)
          }
        }
      }

      if #available(macOS 11.0, *) {
        avPlayer.currentItem?.allowedAudioSpatializationFormats = .monoStereoAndMultichannel
      }

      avPlayer.currentItem?.preferredForwardBufferDuration = CMTimeGetSeconds(CMTime(seconds: 120))

      // Seek to existing position
      if episode.playPosition > 0 {
        seek(seconds: Double(episode.playPosition))
      }

      avPlayer.volume = volume

      currentEpisode = episode
      postNowPlayingEpisodeUpdates()

      avPlayer.play()
      beginRoutingArbitration()
    }
  }

  private func destroyAVPlayerAndResetState() {
    currentAVAsset = nil

    // Destroy any existing player
    if let avPlayer = avPlayer {
      // Destroy the existing player and let a new one be created
      avPlayer.pause()
      while !periodicTimeObservers.isEmpty {
        avPlayer.removeTimeObserver(periodicTimeObservers.popLast()!)
      }
      self.avPlayer = nil
    }

    leaveRoutingArbitration()

    // Reset local states
    loadStatus = .none
    currentEpisode = nil
    currentPlaybackURL = nil
    duration = 0
    buffered = 0
    position = 0
    pausedAt = nil
    isSeeking = false

    postNowPlayingEpisodeUpdates()
    postPlaybackStatusUpdates()
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    if object as? AVPlayer == avPlayer {
      if keyPath == "status" {
        switch avPlayer?.status {
        case .readyToPlay?:
          loadStatus = .playing
        default:
          loadStatus = .none
        }

        Self.log(level: .debug, "Playing")
        postPlaybackStatusUpdates()
      }
    }
  }

  @objc func playerDidFinishPlaying(notification: NSNotification) {
    if let episode = currentEpisode {
      episode.played = true
      episode.playPosition = 0
      Library.global.save(episode: episode)
    }
  }

  private func postNowPlayingEpisodeUpdates() {
     delegate?.update(forEpisode: currentEpisode)
     updateNowPlayingEpisodeInfo()
   }

  private func postPlaybackStatusUpdates() {
    delegate?.updatePlayback()
    updateNowPlayingPlaybackInfo()
  }

  private func buildAVPlayerHTTPHeaders() -> [String: String] {
    return [
      "User-Agent": self.userAgent,
    ]
  }

  private static func buildUserAgent() -> String {
    let processInfo = ProcessInfo()

    var bundleVersion = ""
    var bundleShortVersion = ""
    if let infoDict = Bundle.main.infoDictionary {
      bundleVersion = (infoDict["CFBundleVersion"] as? String) ?? ""
      bundleShortVersion = (infoDict["CFBundleShortVersionString"] as? String) ?? ""
    }

    return "Doughnut/\(bundleShortVersion).\(bundleVersion) (+https://doughnutapp.com/; Podcast Client; macOS \(processInfo.operatingSystemVersionString))"
  }

  // MARK: - Actions

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

  func stop() {
    destroyAVPlayerAndResetState()
  }

  func skipAhead(seconds: Double? = nil) {
    guard let av = avPlayer else { return }
    guard let duration = av.currentItem?.duration else { return }

    let currentTime = CMTimeGetSeconds(av.currentTime())
    let skipDuration = seconds ?? Preference.double(for: Preference.Key.skipForwardDuration)
    var targetTime = currentTime + skipDuration

    if targetTime > CMTimeGetSeconds(duration) {
      targetTime = CMTimeGetSeconds(duration)
    }

    seek(seconds: targetTime)
  }

  func skipBack(seconds: Double? = nil) {
    guard let av = avPlayer else { return }

    let currentTime = CMTimeGetSeconds(av.currentTime())
    let skipDuration = seconds ?? Preference.double(for: Preference.Key.skipBackDuration)
    var targetTime = currentTime - skipDuration

    if targetTime < 0 {
      targetTime = 0
    }

    seek(seconds: targetTime)
  }

  func seek(seconds: Double) {
    guard let av = avPlayer else { return }

    isSeeking = true
    Self.log(level: .debug, "seek started")
    av.seek(to: CMTime(seconds: seconds)) { [weak self] finished in
      guard let self = self else { return }
      Self.log(level: .debug, "seek completionHandler called, finished: \(finished)")
      if finished == true {
        self.isSeeking = false
      }
    }
  }

  private func beginRoutingArbitration() {
    if #available(macOS 11.0, *) {
      AVAudioRoutingArbiter.shared.begin(category: .playback) { defaultDeviceChanged, error in
        if let error = error {
          Self.log(level: .error, "begins routing arbitration failed, defaultDeviceChanged: \(defaultDeviceChanged), error: \(error)")
        } else {
          Self.log(level: .debug, "begins routing arbitration, defaultDeviceChanged: \(defaultDeviceChanged)")
        }
      }
    }
  }

  private func leaveRoutingArbitration() {
    if #available(macOS 11.0, *) {
      AVAudioRoutingArbiter.shared.leave()
      Self.log(level: .debug, "leaves routing arbitration")
    }
  }

  // MARK: -

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

      // swiftlint:disable:next no_direct_standard_out_logs
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
