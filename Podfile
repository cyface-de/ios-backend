workspace 'DataCapturing.xcworkspace'
platform :ios, '12.4'
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
