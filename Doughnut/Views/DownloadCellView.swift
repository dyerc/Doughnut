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

class DownloadCellView: NSTableCellView, DownloadProgressDelegate {
  @IBOutlet weak var episodeTitle: NSTextField!
  @IBOutlet weak var progressBar: NSProgressIndicator!
  @IBOutlet weak var progressText: NSTextField!
  
  let byteFormatter = ByteCountFormatter()
  
  var download: DownloadTask? {
    didSet {
      download?.progressDelegate = self
      
      byteFormatter.allowedUnits = .useMB
      byteFormatter.countStyle = .file
      
      episodeTitle.stringValue = download?.episode.title ?? ""
    }
  }
  
  func download(progressed download: DownloadTask) {
    if download.totalBytes > 0 {
      progressBar.stopAnimation(self)
      progressBar.minValue = 0
      progressBar.maxValue = 1
      progressBar.isIndeterminate = false
      progressBar.doubleValue = download.progressedBytes / download.totalBytes

      progressText.stringValue = "\(byteFormatter.string(fromByteCount: Int64(download.progressedBytes))) of \(byteFormatter.string(fromByteCount: Int64(download.totalBytes)))"
    } else {
      progressBar.startAnimation(self)
      progressBar.isIndeterminate = true
      progressBar.doubleValue = 0
      progressBar.minValue = 0
      progressBar.maxValue = 0
      
      progressText.stringValue = "Unknown"
    }
  }
}
