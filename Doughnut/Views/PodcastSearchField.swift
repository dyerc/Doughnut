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

protocol PodcastSearchFieldDelegate: AnyObject {

  func podcastSearchFieldDidUpdate(withFilter filter: PodcastViewController.Filter)

}

final class PodcastSearchField: NSSearchField {

  weak var searchFieldDelegate: PodcastSearchFieldDelegate?

  private var filter: PodcastViewController.Filter = .all {
    didSet {
      updateFilteringButtonState()
      searchFieldDelegate?.podcastSearchFieldDidUpdate(withFilter: filter)
    }
  }

  private var previousFilterCategory: PodcastViewController.Filter.Category = .newEpisodes

  // NSButtonCell has no methods fo tintColor, images have to be tinted manually
  private var filterImage: NSImage?
  private var filterImageActive: NSImage?
  private var cancelImage: NSImage?
  private var controlSelectedImage: NSImage?

  private static let searchButtonSize = CGSize(width: 32, height: 16)

  init() {
    super.init(frame: .zero)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    updateIconImages()

    let searchFieldCell = cell as? NSSearchFieldCell
    searchFieldCell?.searchButtonCell?.imageScaling = .scaleProportionallyDown
    searchFieldCell?.cancelButtonCell?.imageScaling = .scaleProportionallyDown

    target = self
    action = #selector(onSearchTextChange(_:))

    let menu = NSMenu()

    menu.addItem(withTitle: "Filter by", action: nil, keyEquivalent: "")

    let newEpisodesItem = NSMenuItem(title: "New Episodes", action: #selector(toggleFilterPodcasts(_:)), keyEquivalent: "")
    newEpisodesItem.indentationLevel = 1
    menu.addItem(newEpisodesItem)

    for item in menu.items[0...] {
      item.configureWithDefaultFont()
    }
    searchMenuTemplate = menu
  }

  private func updateIconImages() {
    filterImage = NSImage(named: "PodcastFilter")?.tinted(with: .secondaryLabelColor)
    filterImageActive = NSImage(named: "PodcastFilterActive")?.tinted(with: .controlAccentColor)

    cancelImage = NSImage(named: NSImage.stopProgressFreestandingTemplateName)?.tinted(with: .secondaryLabelColor)
    controlSelectedImage = NSImage(named: NSImage.stopProgressFreestandingTemplateName)?.tinted(with: .labelColor)

    let searchFieldCell = cell as? NSSearchFieldCell
    searchFieldCell?.cancelButtonCell?.image = cancelImage
    searchFieldCell?.cancelButtonCell?.alternateImage = controlSelectedImage

    updateFilteringButtonState()
  }

  override func draw(_ dirtyRect: NSRect) {
    // This override is required, otherwise icon images won't update
    super.draw(dirtyRect)
  }

  override func rectForSearchButton(whenCentered isCentered: Bool) -> NSRect {
    let originalRect = super.rectForSearchButton(whenCentered: isCentered)
    return CGRect(
      x: originalRect.origin.x,
      y: originalRect.origin.y - (Self.searchButtonSize.height - originalRect.size.height) / 2,
      width: Self.searchButtonSize.width,
      height: Self.searchButtonSize.height
    )
  }

  override func rectForSearchText(whenCentered isCentered: Bool) -> NSRect {
    var rect = super.rectForSearchText(whenCentered: isCentered)
    let searchButtonRect = super.rectForSearchButton(whenCentered: isCentered)
    rect.origin.x += Self.searchButtonSize.width - searchButtonRect.width
    rect.size.width -= Self.searchButtonSize.width - searchButtonRect.width
    return rect
  }

  override func viewDidChangeEffectiveAppearance() {
    NSAppearance.withAppAppearance {
      updateIconImages()
    }
  }

  override func mouseDown(with event: NSEvent) {
    // If the click resides on the left half of the filter icon, perform a
    // toggle against previous selected filter category, otherwise, fall back to
    // the default behavior that shows the category menu.
    let searchButtonRect = rectForSearchButton(whenCentered: centersPlaceholder)
    let pointInSearchField = convert(event.locationInWindow, from: nil)
    if
      searchButtonRect.contains(pointInSearchField),
      pointInSearchField.x <= searchButtonRect.midX,
      filter.query.isEmpty
    {
      swap(&previousFilterCategory, &filter.category)
    } else {
      super.mouseDown(with: event)
    }
  }

  private func updateFilteringButtonState() {
    let isActive = !filter.query.isEmpty || filter.category != .all
    let searchFieldCell = cell as? NSSearchFieldCell
    // On 10.15, `alternateImage` shows above `image`, rather than replacing it.
    // thus togging `state` results poor result, we have to set `image` directly.
    searchFieldCell?.searchButtonCell?.image = isActive ? filterImageActive : filterImage
    needsDisplay = true
  }

  @objc func toggleFilterPodcasts(_ sender: Any) {
    previousFilterCategory = filter.category
    filter.category = (filter.category == .newEpisodes) ? .all : .newEpisodes
  }

  @objc func onSearchTextChange(_ sender: Any) {
    filter.query = stringValue
  }

  @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    switch menuItem.action {
    case #selector(toggleFilterPodcasts(_:)):
      menuItem.state = filter.category == .newEpisodes ? .on : .off
      return true
    default:
      return false
    }
  }

}
