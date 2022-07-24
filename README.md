<h1 align="center">
  <img src="./Assets/icon.png" alt="Doughnut" width="200">
  <br>
  Doughnut
  <br>
</h1>

<h4 align="center">Podcast app. For Mac.</h4>

<p align="center">
  <a href="https://github.com/serhii-londar/open-source-mac-os-apps#podcast"><img src="https://awesome.re/mentioned-badge.svg" alt="Mentioned in Awesome" /></a>
  <a href="https://github.com/dyerc/Doughnut/releases"><img src="https://img.shields.io/github/release/dyerc/doughnut.svg" alt="Github Release"></a>
</p>

<p align="center">
  <code>brew install --cask doughnut</code>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/dyerc/Doughnut/master/screenshot.png?v=2" align="center" alt="screenshot" style="max-width:100%;" />
</p>

Doughnut is a podcast client built using Swift. The design and user experience are inspired by Instacast for Mac which was discontinued in 2015. After experimenting with alternate user interface layouts, I kept coming back to the three column layout as most useable and practical.

Beyond the standard expected podcast app features, my goals for the project are:
- [x] Support an iTunes style library that can be hosted on an internal or network shared drive 
- [x] Ability to favourite episodes
- [x] Ability to create podcasts without a feed, for miscellaneous releases of discontinued podcasts

Previously Doughnut was built on top of Electron which worked ok, but using 200+ MB for a podcast app, even when it's minimized felt very poor. Doughnut is now written as a 100% native MacOS app in Swift.

## How to Contribute

### Local Environments

* Xcode 12.2+, latest stable release is recommended, but not required.

* Install [SwiftLint](https://github.com/realm/SwiftLint).

  ```shell
  brew install swiftlint
  ```

### Get the code

```
git clone git@github.com:dyerc/Doughnut.git
cd Doughnut
open Doughnut.xcodeproj
```

### Building

* `Debug` configuration can be directly built once Xcode finishes fetching all the packages.

* To build for `Release` configuration, update the code signing configurations in `Configs/DoughnutCodeSigning-Release.xcconfig` to desired values, or switch to the ad-hoc configurations within `Configs/Doughnut-Release.xcconfig`.
