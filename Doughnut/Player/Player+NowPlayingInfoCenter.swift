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

import Foundation
import MediaPlayer

extension Player {

  private var nowPlayingPlaybackState: MPNowPlayingPlaybackState {
    switch loadStatus {
    case .none:
      return .stopped
    case .loading:
      return .paused
    case .playing:
      if let avPlayer = avPlayer {
        return avPlayer.rate == .zero ? .paused : .playing
      } else {
        return .stopped
      }
    }
  }

  func updateNowPlayingEpisodeInfo() {
    Self.log(level: .debug, "[NowPlayingInfo]: updateNowPlayingEpisodeInfo called")

    guard let currentEpisode = currentEpisode else {
      nowPlayingEpisodeInfoDictionary = [:]
      return
    }

    var info: [String: Any] = [
      MPMediaItemPropertyTitle: currentEpisode.title,
      MPMediaItemPropertyArtist: currentEpisode.podcast?.author ?? "",

      MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
      MPNowPlayingInfoPropertyIsLiveStream: false,
      MPNowPlayingInfoPropertyExternalContentIdentifier: currentEpisode.guid,
      MPNowPlayingInfoPropertyPlaybackProgress: currentEpisode.played ? 0.0 : 1.0,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
    ]

    if let image = currentEpisode.artwork ?? currentEpisode.podcast?.image {
      info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in image })
    }

    if let url = currentPlaybackURL {
      info[MPNowPlayingInfoPropertyAssetURL] = url
    }

    nowPlayingEpisodeInfoDictionary = info
  }

  func updateNowPlayingPlaybackInfo() {
    // Self.logger.debug("[NowPlayingInfo]: updateNowPlayingPlaybackInfo called")

    // TODO: Limit the rate of sending the following values.
    let nowPlayingInfoDictionary = nowPlayingEpisodeInfoDictionary.merging([
      MPMediaItemPropertyPlaybackDuration: Double(duration),
      MPNowPlayingInfoPropertyElapsedPlaybackTime: position,
      MPNowPlayingInfoPropertyPlaybackRate: avPlayer?.rate ?? 1.0,
    ]) { $1 }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfoDictionary

    MPNowPlayingInfoCenter.default().playbackState = nowPlayingPlaybackState
  }

}
