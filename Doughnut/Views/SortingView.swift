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

import Cocoa

enum SortDirection: String {
  case Asc = "Ascending"
  case Desc = "Descending"
}

class SortMenuButtonView: NSButton {
  var trackingArea: NSTrackingArea?
  var textLabel: String = "Sort by" {
    didSet {
      updateLabel()
    }
  }
  let textFont = NSFont.systemFont(ofSize: 11)
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override func mouseEntered(with event: NSEvent) {
    isBordered = true
    updateLabel()
  }
  
  override func mouseExited(with event: NSEvent) {
    isBordered = false
    updateLabel()
  }
  
  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    
    if let trackingArea = trackingArea {
      removeTrackingArea(trackingArea)
    }
    
    trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
    addTrackingArea(trackingArea!)
  }
  
  func updateLabel() {
    var color = NSColor.gray
    let string = " \(textLabel)"
    
    if isBordered {
      color = NSColor.white
    }
    
    let attributedString = NSAttributedString(string: string, attributes: [
      NSAttributedStringKey.font: textFont,
      NSAttributedStringKey.foregroundColor: color
    ])
    
    let newFrame = NSRect(x: frame.minX, y: frame.minY, width: attributedString.size().width + 10, height: frame.height)
    attributedTitle = attributedString
    frame = newFrame
  }
}

protocol SortingViewDelegate {
  func sorted(by: String?, direction: SortDirection)
}

class SortingView: NSView {
  let menuButtonView: SortMenuButtonView = SortMenuButtonView()
  let sortMenu = NSMenu()
  
  var menuItems: [NSMenuItem] = []
  var directionMenuItems: [NSMenuItem] = []
  
  var delegate: SortingViewDelegate?
  open var menuItemTitles: [String] = [] {
    didSet {
      buildMenu()
    }
  }
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    
    // Background
    wantsLayer = true
    layer?.backgroundColor = NSColor(calibratedRed: 0.961, green: 0.961, blue: 0.961, alpha: 1.0).cgColor
    
    // Setup inline button
    menuButtonView.frame = NSRect(x: 2, y: 2, width: 0, height: 16)
    menuButtonView.bezelStyle = .inline
    menuButtonView.setButtonType(.momentaryPushIn)
    menuButtonView.state = .off
    menuButtonView.isBordered = false
    menuButtonView.imagePosition = .imageRight
    menuButtonView.textLabel = "Sort by Unknown"
    menuButtonView.action = #selector(showMenu)
    menuButtonView.target = self
    
    directionMenuItems.append(NSMenuItem(title: SortDirection.Asc.rawValue, action: #selector(performSortDirection), keyEquivalent: ""))
    directionMenuItems.append(NSMenuItem(title: SortDirection.Desc.rawValue, action: #selector(performSortDirection), keyEquivalent: ""))
    
    buildMenu()
    
    addSubview(menuButtonView)
  }
  
  func buildMenu() {
    sortMenu.removeAllItems()
    
    for title in menuItemTitles {
      let item = NSMenuItem(title: title, action: #selector(performSort), keyEquivalent: "")
      item.target = self
      menuItems.append(item)
      sortMenu.addItem(item)
      
      if title == sortParam {
        item.state = .on
        menuButtonView.textLabel = "Sort by \(item.title)"
      }
    }
    
    sortMenu.addItem(NSMenuItem.separator())
    
    for item in directionMenuItems {
      item.target = self
      sortMenu.addItem(item)
    }
  }
  
  override func resizeSubviews(withOldSize oldSize: NSSize) {
    menuButtonView.updateLabel()
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    let bottomBorder = NSBezierPath()
    bottomBorder.move(to: NSPoint(x: 0, y: 0))
    bottomBorder.line(to: NSPoint(x: bounds.width, y: 0))
    
    NSColor.lightGray.setStroke()
    bottomBorder.stroke()
  }
  
  @objc func showMenu(_ sender: Any) {
    sortMenu.popUp(positioning: nil, at: NSPoint(x: menuButtonView.bounds.minX, y: menuButtonView.bounds.minY), in: self)
  }
  
  var sortParam: String? {
    get {
      for item in menuItems {
        if item.state == .on {
          return item.title
        }
      }
      
      return nil
    }
    
    set {
      for item in menuItems {
        if item.title == newValue {
          item.state = .on
          menuButtonView.textLabel = "Sort by \(item.title)"
        } else {
          item.state = .off
        }
      }
    }
  }
  
  @objc func performSort(_ sender: NSMenuItem) {
    for item in menuItems {
      if item == sender {
        item.state = .on
        menuButtonView.textLabel = "Sort by \(item.title)"
      } else {
        item.state = .off
      }
    }
    
    delegate?.sorted(by: sortParam, direction: sortDirection)
  }
  
  var sortDirection: SortDirection {
    get {
      for item in directionMenuItems {
        if item.state == .on && item.title == SortDirection.Desc.rawValue {
          return .Desc
        }
      }
      
      return .Asc
    }
    
    set {
      for item in directionMenuItems {
        if item.title == newValue.rawValue {
          item.state = .on
        } else {
          item.state = .off
        }
      }
    }
  }
  
  @objc func performSortDirection(_ sender: NSMenuItem) {
    for item in directionMenuItems {
      if item == sender {
        item.state = .on
      } else {
        item.state = .off
      }
    }
    
    delegate?.sorted(by: sortParam, direction: sortDirection)
  }
}
