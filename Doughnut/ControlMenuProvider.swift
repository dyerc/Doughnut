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

import AppKit
import Foundation

final class ControlMenuProvider {

  static let shared = ControlMenuProvider()

  private init() { }

  func buildControlMenuItems(isForDockMenu: Bool) -> [NSMenuItem] {
    var menuItems = [NSMenuItem]()

    let player = Player.global
    let isCurrentlyPlaying = player.currentEpisode != nil

    // Now Playing
    if
      isForDockMenu,
      isCurrentlyPlaying,
      let currentEpisode = player.currentEpisode,
      !currentEpisode.title.isEmpty
    {
      let formatNowPlayingTitle: (Episode) -> String = { episode in
        if let podcastTitle = episode.podcast?.title {
          return "\(episode.title) - \(podcastTitle)"
        } else {
          return episode.title
        }
      }

      menuItems.append(
        NSMenuItem(
          title: "Now Playing",
          action: nil,
          keyEquivalent: ""
        )
      )

      let nowPlayingItem = NSMenuItem(
        title: formatNowPlayingTitle(currentEpisode),
        action: nil,
        keyEquivalent: ""
      )
      nowPlayingItem.indentationLevel = 1
      menuItems.append(nowPlayingItem)

      menuItems.append(.separator())
    }

    // Play / Pause
    let togglePlayItem = NSMenuItem(
      title: player.isPlaying ? "Pause" : "Play",
      action: #selector(playerToggle(_:)),
      keyEquivalent: " "
    )
    togglePlayItem.target = self
    togglePlayItem.keyEquivalentModifierMask = []
    togglePlayItem.isEnabled = isCurrentlyPlaying
    menuItems.append(togglePlayItem)

    // Skip / Rewind
    if !isForDockMenu || isCurrentlyPlaying {
      let skipForwardDuration = Preference.double(for: Preference.Key.skipForwardDuration)
      let skipBackawrdDuration = Preference.double(for: Preference.Key.skipBackDuration)

      let formatSkipping: (String, TimeInterval) -> String = { title, duration in
        if duration >= 60 {
          return "\(title) \(Int(duration / 60)) Minutes"
        } else {
          return "\(title) \(Int(duration)) Seconds"
        }
      }

      // Skip
      let skipForwardItem = NSMenuItem(
        title: formatSkipping("Skip", skipForwardDuration),
        action: #selector(playerForward(_:)),
        keyEquivalent: String(Unicode.Scalar(NSRightArrowFunctionKey)!)
      )
      skipForwardItem.target = self
      skipForwardItem.isEnabled = isCurrentlyPlaying
      menuItems.append(skipForwardItem)

      // Rewind
      let skipBackwardItem = NSMenuItem(
        title: formatSkipping("Rewind", skipBackawrdDuration),
        action: #selector(playerBackward(_:)),
        keyEquivalent: String(Unicode.Scalar(NSLeftArrowFunctionKey)!)
      )
      skipBackwardItem.target = self
      skipBackwardItem.isEnabled = isCurrentlyPlaying
      menuItems.append(skipBackwardItem)
    }

    if !isForDockMenu {
      // Separator
      menuItems.append(.separator())

      // Volume Up
      let volumeUpItem = NSMenuItem(
        title: "Increase Volume",
        action: #selector(volumeUp(_:)),
        keyEquivalent: String(Unicode.Scalar(NSUpArrowFunctionKey)!)
      )
      volumeUpItem.target = self
      menuItems.append(volumeUpItem)

      // Volume Down
      let volumeDownItem = NSMenuItem(
        title: "Decrease Volume",
        action: #selector(volumeDown(_:)),
        keyEquivalent: String(Unicode.Scalar(NSDownArrowFunctionKey)!)
      )
      volumeDownItem.target = self
      menuItems.append(volumeDownItem)
    }

    return menuItems
  }

  @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    return menuItem.isEnabled
  }

  // Actions

  @objc func playerBackward(_ sender: Any) {
    Player.global.skipBack()
  }

  @objc func playerToggle(_ sender: Any) {
    Player.global.togglePlay()
  }

  @objc func playerForward(_ sender: Any) {
    Player.global.skipAhead()
  }

  @objc func volumeUp(_ sender: Any) {
    let current = Player.global.volume
    Player.global.volume = min(current + 0.1, 1.0)
  }

  @objc func volumeDown(_ sender: Any) {
    let current = Player.global.volume
    Player.global.volume = max(current - 0.1, 0.0)
  }

}
