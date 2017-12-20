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

class EditPodcastViewController: NSViewController {
  @IBOutlet weak var titleTxt: NSTextField!
  @IBOutlet weak var authorTxt: NSTextField!
  @IBOutlet weak var descriptionTxt: NSTextField!
  
  var podcast: Podcast?
  
  override func viewDidLoad() {
    
  }
  
  func validate() -> Bool {
    var error: String? = nil
    
    if (titleTxt.stringValue.characters.count < 1) {
      error = "Podcast must have a title"
    }
    
    if let error = error {
      let alert = NSAlert()
      alert.messageText = error
      alert.runModal()
      
      return false
    } else {
      return true
    }
  }
  
  @IBAction func savePodcast(_ sender: Any) {
    guard validate() else { return }
    
    if let podcast = podcast {
      Library.global.save(podcast: podcast)
      dismiss(self)
    } else {
      // Create new podcast
      let podcast = Podcast(title: titleTxt.stringValue)
      podcast.author = authorTxt.stringValue
      podcast.description = descriptionTxt.stringValue
      
      Library.global.subscribe(podcast: podcast)
      dismiss(self)
    }
  }
}
