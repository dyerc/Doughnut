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

import CrashReporter

final class CrashReporter {

  static var shared: CrashReporter {
    return sharedInstance
  }

  private static var sharedInstance = CrashReporter()

  private var plCrashReporter: PLCrashReporter?

  private init() {
    let config = PLCrashReporterConfig.defaultConfiguration()
    guard let plCrashReporter = PLCrashReporter(configuration: config) else {
      print("CrashReporter: could not create an instance of PLCrashReporter")
      return
    }
    self.plCrashReporter = plCrashReporter
    // enable the PLCrashReporter
    do {
      try plCrashReporter.enableAndReturnError()
    } catch {
      print("CrashReporter: failed to enable PLCrashReporter: \(error)")
    }
  }

  func getPendingCrashReport() -> String? {
    guard
      let plCrashReporter = plCrashReporter,
      plCrashReporter.hasPendingCrashReport()
    else {
      return nil
    }

    defer {
      // purge the report
      plCrashReporter.purgePendingCrashReport()
    }

    do {
      let data = try plCrashReporter.loadPendingCrashReportDataAndReturnError()

      // retrieve crash reporter data
      let report = try PLCrashReport(data: data)

      if let text = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS) {
        return text
      } else {
        print("CrashReporter: can't convert the report to text")
      }
    } catch {
      print("CrashReporter failed to load and parse crash report: \(error)")
    }

    return nil
  }

  func forceCrash() {
    fatalError("Force crashd in \(#function)")
  }

}
