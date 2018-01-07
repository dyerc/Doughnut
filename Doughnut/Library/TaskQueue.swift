//
//  TaskQueue.swift
//  Doughnut
//
//  Created by Chris Dyer on 02/01/2018.
//  Copyright © 2018 Chris Dyer. All rights reserved.
//

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
    
    success = { object in }
    failure = { object in }
    
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

// let task = DownloadTask(episode, porcast)
// task.success =
// Library.global.queue.push(task)

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
