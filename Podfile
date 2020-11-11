workspace 'DataCapturing.xcworkspace'
platform :ios, '12.4'
use_frameworks!

target 'Example' do
  project 'Example/Example.xcodeproj'
  pod 'Charts', '~> 3.4.0'
  pod 'DataCapturing', :path => './DataCapturing'

  target 'Tests' do
    inherit! :search_paths
    # Pods for testing
    pod 'DataCapturing', :path => './DataCapturing'
  end
end
