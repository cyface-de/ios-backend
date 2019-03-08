platform :ios, '11.0'

target 'DataCapturing' do
  use_frameworks!

  # Used for network traffic
  pod 'Alamofire', '~> 4.8.1'
  # A wrapper for the complicated ObjectiveC compression API.
  pod 'DataCompression', '~> 3.1.0'

  target 'DataCapturingTests' do
    #inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
   installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            # This works around a unit test issue introduced in Xcode 10.
            # We only apply it to the Debug configuration to avoid bloating the app size
	    # This seems to be fixed in XCode 10.2. So as soon as the update is available we shoud remove this piece of code.
            # See: https://github.com/CocoaPods/CocoaPods/issues/8139
            # It might also be necessary to uncomment `inherit! :search_paths` under the DataCapturingTests target again.
            if config.name == "Debug" && defined?(target.product_type) && target.product_type == "com.apple.product-type.framework"
                config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = "YES"
            end
        end
    end
end
