# Uncomment the next line to define a global platform for your project
platform :osx, '10.15'

target 'Doughnut' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks! :linkage => :static

  # Pods for Doughnut
  pod 'GRDB.swift', '5.17.0'
  pod 'FeedKit', '9.1.2'
  pod 'MASPreferences', '1.4.1'
  pod 'Sparkle', '1.27.1'
  pod 'PLCrashReporter', '1.10.1'
end

target 'DoughnutTests' do
  use_frameworks!
  inherit! :search_paths
  # Pods for testing
end

target 'DoughnutUITests' do
  use_frameworks!
  inherit! :search_paths
  # Pods for testing
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'ARCHS'
    end
  end
end
