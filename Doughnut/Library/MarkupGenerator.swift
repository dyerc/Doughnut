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

class MarkupGenerator {

  static var styles: String = {
    guard
      let styleSheetPath = Bundle.main.path(forResource: "detail", ofType: "css"),
      let styleSheet = try? String(contentsOf: URL(fileURLWithPath: styleSheetPath), encoding: .utf8)
    else {
      fatalError("Failed to load the default style sheet.")
    }
    return styleSheet
  }()

  static func template(_ yield: String) -> String {
    return """
    <html>
      <head>
        <style>\(styles)</style>
        <script src="detail.js"></script>
        <script>
          document.addEventListener("DOMContentLoaded", function(event) {
            processDetailPage();
          });
        </script>
      </head>
      <body>
        \(yield)
      </body>
    </html>
    """
  }

  static func blankMarkup() -> String {
    return template("")
  }

  static func markup(forPodcast podcast: Podcast) -> String {
    return template("""
      <hr />
      <p>\(podcast.description ?? "")</p>
    """)
  }

  static func markup(forEpisode episode: Episode) -> String {
    return template("""
      <hr />
      <p>\(episode.description ?? "")</p>
    """)
  }
}
