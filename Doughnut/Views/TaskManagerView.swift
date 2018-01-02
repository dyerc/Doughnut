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

class TaskView: NSView {
  let titleLabelView: NSTextField
  let progressView: NSProgressIndicator
  
  override init(frame frameRect: NSRect) {
    titleLabelView = NSTextField(frame: NSRect(x: 0, y: 24, width: frameRect.width, height: 17))
    titleLabelView.stringValue = "Task Title"
    titleLabelView.isBezeled = false
    titleLabelView.drawsBackground = false
    titleLabelView.isSelectable = false
    titleLabelView.font = NSFont.systemFont(ofSize: 12)
    titleLabelView.isEditable = false
    
    progressView = NSProgressIndicator(frame: NSRect(x: 0, y: 4, width: frameRect.width, height: 20))
    progressView.isIndeterminate = true
    progressView.style = .bar
    
    super.init(frame: frameRect)
    
    addSubview(titleLabelView)
    addSubview(progressView)
    progressView.startAnimation(self)
  }
  
  required convenience init?(coder decoder: NSCoder) {
    self.init(frame: NSRect())
  }
  
  override var intrinsicContentSize: NSSize {
    get {
      return NSSize(width: bounds.size.width, height: 44)
    }
  }
}

class TaskManagerView: NSView {
  let activitySpinner = ActivityIndicator()
  let popover = NSPopover()
  
  var downloadsController: DownloadsViewController?
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    
    popover.behavior = .transient
    
    activitySpinner.frame = self.bounds
    addSubview(activitySpinner)
    
    let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
    downloadsController = (storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "DownloadsPopover")) as! DownloadsViewController)
  }
  
  override func mouseDown(with event: NSEvent) {
    popover.contentViewController = downloadsController
    popover.show(relativeTo: bounds, of: activitySpinner, preferredEdge: .minY)
  }
}
