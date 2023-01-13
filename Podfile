workspace 'DataCapturing.xcworkspace'
platform :ios, '12.4'
use_frameworks!

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
