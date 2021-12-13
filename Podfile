# Uncomment the next line to define a global platform for your project
platform :osx, '10.12'

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

  pod 'GRDB.swift'
  pod 'FeedKit', :git => 'https://github.com/dyerc/FeedKit.git'
  pod 'MASPreferences'
  pod 'Sparkle'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
        end
    end
  end
end
