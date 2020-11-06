workspace 'DataCapturing.xcworkspace'
platform :ios, '12.4'

target 'Example' do
  use_frameworks!
  project 'Example/Example.xcodeproj'
  pod 'Charts', '~> 3.4.0'
  pod 'DataCapturing', :path => './DataCapturing'

  target 'UITests' do
    inherit! :search_paths
    # Pods for ui testing
  end

  target 'Tests' do
    inherit! :search_paths
    # Pods for testing
  end
end

#target 'DataCapturing' do
  # Comment the next line if you don't want to use dynamic frameworks
  #use_frameworks!
  #project 'DataCapturing/DataCapturing.xcodeproj'

  # Pods for DataCapturing
  #pod 'Alamofire', '~> 4.9.0'
  #pod 'DataCompression', '~> 3.4.0'

  #target 'DataCapturingTests' do
    # Pods for testing
  #end

#end
