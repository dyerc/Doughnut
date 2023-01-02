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

import Cocoa

let TASK_VIEW_HEIGHT: CGFloat = 55

class TaskView: NSView, TaskProgressDelegate {
  let titleLabelView: NSTextField
  let progressView: NSProgressIndicator
  let informationLabelView: NSTextField

  let task: Task

  init(task: Task, frame frameRect: NSRect) {
    self.task = task

    titleLabelView = NSTextField(frame: NSRect(x: 0, y: 38, width: frameRect.width, height: 17))
    titleLabelView.stringValue = task.name
    titleLabelView.isBezeled = false
    titleLabelView.drawsBackground = false
    titleLabelView.isSelectable = false
    titleLabelView.font = NSFont.systemFont(ofSize: 12)
    titleLabelView.isEditable = false

    progressView = NSProgressIndicator(frame: NSRect(x: 0, y: 18, width: frameRect.width, height: 20))
    progressView.minValue = 0
    progressView.maxValue = 0
    progressView.doubleValue = 0
    progressView.isIndeterminate = true
    progressView.style = .bar

    informationLabelView = NSTextField(frame: NSRect(x: 0, y: 4, width: frameRect.width, height: 14))
    informationLabelView.stringValue = task.detailInformation ?? ""
    informationLabelView.isBezeled = false
    informationLabelView.drawsBackground = false
    informationLabelView.isSelectable = false
    informationLabelView.font = NSFont.systemFont(ofSize: 10)
    informationLabelView.textColor = NSColor.gray
    informationLabelView.isEditable = false

    super.init(frame: frameRect)

    addSubview(titleLabelView)
    addSubview(progressView)
    addSubview(informationLabelView)
    progressView.startAnimation(self)

    task.progressDelegate = self
  }

  required convenience init?(coder decoder: NSCoder) {
    self.init(task: Task(name: ""), frame: NSRect())
  }

  override var intrinsicContentSize: NSSize {
    return NSSize(width: bounds.size.width, height: TASK_VIEW_HEIGHT)
  }

  func progressed() {
    progressView.isIndeterminate = task.isIndeterminate
    progressView.doubleValue = task.progressValue
    progressView.maxValue = task.progressMax
    informationLabelView.stringValue = task.detailInformation ?? ""
  }
}

class TasksViewController: NSViewController, TaskQueueViewDelegate {
  @IBOutlet weak var stackView: NSStackView!

  override func viewDidLoad() {
    super.viewDidLoad()

    stackView.translatesAutoresizingMaskIntoConstraints = false
  }

  func taskPushed(task: Task) {
    let view = TaskView(task: task, frame: NSRect(x: 0, y: 0, width: stackView.bounds.width, height: TASK_VIEW_HEIGHT))
    stackView.addView(view, in: .top)
  }

  func taskFinished(task: Task) {
    let taskView = stackView.views.first { view -> Bool in
      return (view as! TaskView).task == task
    }

    if let matchedView = taskView {
      stackView.removeView(matchedView)
      matchedView.removeFromSuperview()
    }
  }

  func tasksRunning(_ running: Bool) {

  }
}
