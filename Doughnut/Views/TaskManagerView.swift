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

class TaskManagerView: NSView, TaskQueueViewDelegate {
  let activitySpinner = ActivityIndicator()
  let popover = NSPopover()
  
  var tasksViewController: TasksViewController?
  
  var hasActiveTasks: Bool = false {
    didSet {
      activitySpinner.isHidden = !hasActiveTasks
    }
  }
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    
    Library.global.tasks.delegate = self
    
    popover.behavior = .transient
    
    activitySpinner.frame = self.bounds
    activitySpinner.isHidden = true
    addSubview(activitySpinner)
    
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    tasksViewController = (storyboard.instantiateController(withIdentifier: "TasksPopover") as! TasksViewController)
    tasksViewController?.loadView() // Important: force load views so they exist even before popover is viewed
    popover.contentViewController = tasksViewController
  }
  
  override func mouseDown(with event: NSEvent) {
    if hasActiveTasks {
      popover.show(relativeTo: bounds, of: activitySpinner, preferredEdge: .minY)
    }
  }
  
  func taskPushed(task: Task) {
    tasksViewController?.taskPushed(task: task)
  }
  
  func taskFinished(task: Task) {
    tasksViewController?.taskFinished(task: task)
    
    
  }
  
  func tasksRunning(_ running: Bool) {
    if running {
      hasActiveTasks = true
    } else {
      hasActiveTasks = false
      
      if popover.isShown {
        popover.close()
      }
    }
  }
}
