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

// See MPRemoteCommandCenter.h for all available commands.

extension Player {

  func setupRemoteCommands() {
    let remoteCommandCenter = MPRemoteCommandCenter.shared()

    // Playback Commands

    remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
      Self.log(level: .debug, "[RemoteCommand]: Receive pauseCommand")
      self?.pause()
      return .success
    }

    remoteCommandCenter.playCommand.addTarget { [weak self] _ in
      Self.log(level: .debug, "[RemoteCommand]: Receive playCommand")
      self?.play()
      return .success
    }

    remoteCommandCenter.stopCommand.addTarget { [weak self] _ in
      Self.log(level: .debug, "[RemoteCommand]: Receive stopCommand")
      self?.stop()
      return .success
    }

    remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
      Self.log(level: .debug, "[RemoteCommand]: Receive togglePlayPauseCommand")
      self?.togglePlay()
      return .success
    }

    remoteCommandCenter.enableLanguageOptionCommand.isEnabled = false
    remoteCommandCenter.disableLanguageOptionCommand.isEnabled = false
    remoteCommandCenter.changePlaybackRateCommand.isEnabled = false
    remoteCommandCenter.changeRepeatModeCommand.isEnabled = false
    remoteCommandCenter.changeShuffleModeCommand.isEnabled = false

    // Previous/Next Track Commands

    remoteCommandCenter.nextTrackCommand.isEnabled = false
    remoteCommandCenter.previousTrackCommand.isEnabled = false

    // Skip Interval Commands

    remoteCommandCenter.skipForwardCommand.addTarget { [weak self] event in
      Self.log(level: .debug, "[RemoteCommand]: Receive skipForwardCommand")
      guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
      self?.skipAhead(seconds: event.interval)
      return .success
    }

    remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] event in
      Self.log(level: .debug, "[RemoteCommand]: Receive skipBackwardCommand")
      guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
      self?.skipBack(seconds: event.interval)
      return .success
    }

    // Seek Commands

    remoteCommandCenter.seekForwardCommand.isEnabled = false

    remoteCommandCenter.seekBackwardCommand.isEnabled = false

    remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
      Self.log(level: .debug, "[RemoteCommand]: Receive changePlaybackPositionCommand")
      guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
      self?.seek(seconds: event.positionTime)
      return .success
    }

    remoteCommandCenter.ratingCommand.isEnabled = false

    // Feedback Commands
    // These are generalized to three distinct actions. Your application can provide
    // additional context about these actions with the localizedTitle property in
    // MPFeedbackCommand.

    remoteCommandCenter.likeCommand.isEnabled = false
    remoteCommandCenter.dislikeCommand.isEnabled = false
    remoteCommandCenter.bookmarkCommand.isEnabled = false
  }

}
