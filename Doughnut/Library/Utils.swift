//
//  Utils.swift
//  Doughnut
//
//  Created by Chris Dyer on 15/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

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
    
    let request = URLSession.shared.dataTask(with: iTunesDataUrl) { (data, response, error) in
      guard let data = data, error == nil else {
        completion(nil)
        return
      }
      
      do {
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
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
        print(error)
      }
      
      completion(nil)
    }
    
    request.resume()
    return true
  }
  
  static func iTunesPodcastId(iTunesUrl: String) -> String? {
    let regex = try! NSRegularExpression(pattern: "\\/id(\\d+)")
    let matches = regex.matches(in: iTunesUrl, options: [], range: NSRange(location: 0, length: iTunesUrl.characters.count))
    
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
