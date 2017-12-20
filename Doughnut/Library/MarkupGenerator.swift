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
 
import Foundation

class MarkupGenerator {
  static var styles: String {
    get {
      return """
      * { margin: 0; padding: 0; }
      body {
        font-family: -apple-system, Helvetica, sans-serif;
        font-size: 12px;
        line-height: 19px;
      }
      
      p {
        color: #777777;
        margin: 10px 0;
      }
      
      hr {
        display: block;
        height: 1px;
        border: 0;
        border-top: 1px solid #EEEEEE;
        margin: 5px 0;
        padding: 0;
      }
      
      img {
        max-width: 100%;
      }
      """
    }
  }
  
  static func template(_ yield: String) -> String {
    return """
    <html>
      <head>
        <style>\(styles)</style>
      </head>
      <body>
        \(yield)
      </body>
    </html>
    """
  }
  
  static func markup(forPodcast podcast: Podcast) -> String {
    return template("""
      <hr />
      <p>\(podcast.description ?? "")</p>
      <hr />
    """)
  }
  
  static func markup(forEpisode episode: Episode) -> String {
    return template("""
      <hr />
      <p>\(episode.description ?? "")</p>
      <hr />
    """)
  }
}
