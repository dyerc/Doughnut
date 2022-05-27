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

protocol TaskProgressDelegate {
  func progressed()
}

class Task: NSObject {
  let id = NSUUID().uuidString
  let name: String
  var detailInformation: String? = "Queued"

  var progressDelegate: TaskProgressDelegate?

  var success: (Any?) -> Void
  var failure: (Any?) -> Void

  init(name: String) {
    self.name = name

    success = { _ in }
    failure = { _ in }

    super.init()
  }

  var isIndeterminate: Bool = true
  var progressValue: Double = 0
  var progressMax: Double = 0

  open func perform(queue: DispatchQueue, completion: @escaping (_ success: Bool, _ object: Any?) -> Void) {
    queue.async {
      sleep(10)
      completion(true, nil)
    }
  }

  func emitProgress() {
    if let delegate = progressDelegate {
      DispatchQueue.main.async {
        delegate.progressed()
      }
    }
  }
}

protocol TaskQueueViewDelegate {
  func taskPushed(task: Task)
  func taskFinished(task: Task)
  func tasksRunning(_ running: Bool)
}

class TaskQueue {
  let dispatchQueue = DispatchQueue(label: "com.doughnut.Tasks")

  var tasks = [Task]()

  var delegate: TaskQueueViewDelegate?

  fileprivate(set) var running = false {
    didSet {
      DispatchQueue.main.async {
        self.delegate?.tasksRunning(self.running)
      }
    }
  }

  var count: Int {
    return tasks.count
  }

  func run(_ task: Task) {
    tasks.append(task)

    DispatchQueue.main.async {
      self.delegate?.taskPushed(task: task)
    }

    if !running {
      running = true

      runNextTask()
    }
  }

  func runNextTask() {
    var task: Task? = nil

    if tasks.count > 0 {
      task = tasks.remove(at: 0)
    }

    if let task = task {
      task.perform(queue: dispatchQueue) { (success, object) in
        if success {
          task.success(object)
        } else {
          task.failure(object)
        }

        DispatchQueue.main.async {
          self.delegate?.taskFinished(task: task)
        }

        self.runNextTask()
      }
    } else {
      running = false
    }
  }
}
