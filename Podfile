workspace 'DataCapturing.xcworkspace'
platform :ios, '13.0'
use_frameworks!
source 'https://github.com/cyface-de/ios-podspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'Example' do
  project 'Example.xcodeproj'
  pod 'Charts', '~> 4.1.0'
  pod 'DataCapturing', :path => './', :testspecs => ['Tests']

  target 'ExampleUnitTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'DataCapturing', :path => './'
  end
end

target 'Cyface-App' do
  project 'Cyface-App/Cyface-App.xcodeproj'
  pod 'DataCapturing', :path => './', :testspecs => ['Tests']
  pod 'HCaptcha', '~> 2.3.2'

  target 'Cyface-AppTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'DataCapturing', :path => './'
    pod 'ViewInspector', '~> 0.9.1'
  end

  target 'Cyface-AppUITests' do
    inherit! :search_paths
    # Pods for testing
    pod 'DataCapturing', :path => './'
    pod 'HCaptcha', '~> 2.3.2'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
