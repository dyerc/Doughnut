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

class DownloadsViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  @IBOutlet weak var stackView: NSStackView!
  
  var downloadManager: DownloadManager?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    downloadManager = Library.global.downloadManager
    
    let view1 = TaskView(frame: NSRect(x: 0, y: 0, width: stackView.bounds.width, height: 44))
    //view.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    let view2 = TaskView(frame: NSRect(x: 0, y: 0, width: stackView.bounds.width, height: 44))
    //view2.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    let view3 = TaskView(frame: NSRect(x: 0, y: 0, width: stackView.bounds.width, height: 44))
    
    stackView.addArrangedSubview(view1)
    stackView.addArrangedSubview(view2)
    stackView.addArrangedSubview(view3)
    stackView.translatesAutoresizingMaskIntoConstraints = false
  }
  
  @objc func reloadView() {
    // tableView.reloadData()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    guard let manager = downloadManager else {
      return 0
    }
    
    // return manager.queueCount
    return 2
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let manager = downloadManager else { return nil }
    
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! DownloadCellView
    // result.download = manager.downloads[row]
    
    return result
  }
  
  func downloadStarted() {
    //tableView.reloadData()
  }
  
  func downloadFinished() {
    //tableView.reloadData()
  }
}
