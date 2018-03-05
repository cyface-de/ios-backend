platform :ios, '11.2'
use_frameworks!

target 'DataCapturing' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  # Line has moved outside of target declaration to follow structure from example project
  # use_frameworks!

  # Used to check for WiFi
  pod 'ReachabilitySwift', '~> 4.1.0'
  # Used for network traffic
  pod 'Alamofire', '~> 4.6'
  # A wrapper for the complicated ObjectiveC compression API.
  pod 'DataCompression'

  target 'DataCapturingTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

