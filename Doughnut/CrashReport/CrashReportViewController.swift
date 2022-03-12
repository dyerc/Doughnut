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

import AppKit

final class CrashReportViewController: NSViewController {

  @IBOutlet private weak var contentTextView: NSTextView!

  override func viewDidLoad() {
    super.viewDidLoad()

    contentTextView.font = NSFont.userFixedPitchFont(ofSize: 12)
    contentTextView.textContainerInset = NSSize(width: 4, height: 4)
  }

  override func viewWillAppear() {
    super.viewWillAppear()

    view.window?.level = .modalPanel
    view.window?.isReleasedWhenClosed = true
    view.window?.center()
  }

  func setCrashContent(_ content: String) {
    contentTextView.string = content
  }

  @IBAction private func sendCrashLog(_ sender: Any) {
    if let crashReportURLStr = Bundle.main.infoDictionary?["DoughnutCrashReportURL"] as? String,
       let crashReportURL = URL(string: crashReportURLStr)
    {
      NSWorkspace.shared.open(crashReportURL)
    }
  }

  @IBAction private func dismissCrashReport(_ sender: Any) {
    view.window?.windowController?.close()
  }

}

final class TroubleshootingViewController: NSViewController {

  @IBOutlet weak var resetPreferencesButton: NSButton!
  @IBOutlet weak var relocateLibraryButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    resetPreferencesButton.setTitleColor(NSColor.systemRed)
  }

  @IBAction private func troubleshootingResetPreferences(_ sender: Any) {
    let alert = NSAlert()
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Confirm")
    alert.messageText = "Are you sure you want to restore all preferences to their default settings?"
    alert.informativeText = "You can’t undo this action."

    guard alert.runModal() == .alertSecondButtonReturn else {
      return
    }

    dismiss(self)

    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    UserDefaults.standard.synchronize()

    promptRestart()
  }

  @IBAction private func troubleshootingRelocateLibrary(_ sender: Any) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false

    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    dismiss(self)

    Preference.set(url, for: Preference.Key.libraryPath)

    promptRestart()
  }

  private func promptRestart() {
    let alert = NSAlert()
    alert.addButton(withTitle: "OK")
    alert.messageText = "Doughnut Will Restart"
    alert.informativeText = "Doughnut will restart to apply these changes."

    alert.runModal()

    let task = Process()

    var args = [String]()
    args.append("-c")
    args.append("sleep 0.2; open \"\(Bundle.main.bundlePath)\"")

    task.launchPath = "/bin/sh"
    task.arguments = args
    task.launch()
    NSApp.terminate(self)
  }

}
