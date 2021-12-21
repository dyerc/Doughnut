# Uncomment the next line to define a global platform for your project
platform :osx, '10.15'

target 'Doughnut' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks! :linkage => :static

  # Pods for Doughnut

  target 'DoughnutTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'DoughnutUITests' do
    use_frameworks!
    inherit! :search_paths
    # Pods for testing
  end

  pod 'GRDB.swift', '5.17.0'
  pod 'FeedKit', '9.1.2'
  pod 'MASPreferences', :git => 'https://github.com/shpakovski/MASPreferences.git', :commit => '135869c'
  pod 'Sparkle', '1.27.1'
end
