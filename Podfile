workspace 'DataCapturing.xcworkspace'
platform :ios, '13.0'
use_frameworks!
source 'https://github.com/cyface-de/ios-podspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'Example' do
  project 'Example.xcodeproj'
  pod 'Charts', '~> 3.6.0'
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

  target 'Cyface-AppTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'DataCapturing', :path => './'
  end

  target 'Cyface-AppUITests' do
    inherit! :search_paths
    # Pods for testing
    pod 'DataCapturing', :path => './'
  end
end
