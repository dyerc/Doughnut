//
//  MarkupGenerator.swift
//  Doughnut
//
//  Created by Chris Dyer on 16/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

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
