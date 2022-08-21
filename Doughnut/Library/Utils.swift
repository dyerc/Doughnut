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

class Utils {
  static func formatDuration(_ seconds: Int) -> String {
    guard seconds > 0 else { return "" }

    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .short

    return formatter.string(from: TimeInterval(seconds)) ?? ""
  }

  static func iTunesFeedUrl(iTunesUrl: String, completion: @escaping (_ result: String?) -> Void) -> Bool {
    guard let iTunesId = Utils.iTunesPodcastId(iTunesUrl: iTunesUrl) else {
      return false
    }

    guard let iTunesDataUrl = URL(string: "https://itunes.apple.com/lookup?id=\(iTunesId)&entity=podcast") else {
      return false
    }

    let request = URLSession.shared.dataTask(with: iTunesDataUrl) { data, _, error in
      guard let data = data, error == nil else {
        completion(nil)
        return
      }

      do {
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        let results = json["results"] as? [[String: Any]] ?? []
        for r in results {
          for result in r {
            if result.key == "feedUrl" {
              completion((result.value as! String))
              return
            }
          }
        }
      } catch let error {
        Library.log(level: .error, "Failed to parse iTunes feed with: \(error)")
      }

      completion(nil)
    }

    request.resume()
    return true
  }

  static func iTunesPodcastId(iTunesUrl: String) -> String? {
    // swiftlint:disable:next force_try
    let regex = try! NSRegularExpression(pattern: "\\/id(\\d+)")
    let matches = regex.matches(in: iTunesUrl, options: [], range: NSRange(location: 0, length: iTunesUrl.count))

    for match in matches as [NSTextCheckingResult] {
      // range at index 0: full match
      // range at index 1: first capture group
      let substring = (iTunesUrl as NSString).substring(with: match.range(at: 1))
      return substring
    }

    return nil
  }

  static func dataToUtf8(_ data: Data) -> Data? {
    var convertedString: NSString?
    let encoding = NSString.stringEncoding(for: data, encodingOptions: nil, convertedString: &convertedString, usedLossyConversion: nil)
    if let str = NSString(data: data, encoding: encoding) as String? {
      return str.data(using: .utf8)
    }

    return nil
  }

  static func removeQueryString(url: URL) -> URL {
    let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.query = nil
    components?.fragment = nil
    return components?.url ?? url
  }
}
