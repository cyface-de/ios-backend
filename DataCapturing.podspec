#
# Be sure to run `pod lib lint Cyface.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DataCapturing'
  s.version          = '1.0.0'
  s.summary          = 'Framework used to continuously capture data from all available sensors on an iOS device and transmit it to a Cyface-API compatible server.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This framework can be included by your App if you are going to capture sensor data and transmit that data to a Cyface-API server for further analysis.
                       DESC

  s.homepage         = 'https://cyface.de'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'GPL', :file => 'LICENSE' }
  s.author           = 'Klemens Muthmann'
  s.source           = { :git => 'https://github.com/cyface-de/ios-backend.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/CyfaceDE'

  s.platform	     = :ios, '11.2'

  s.source_files = 'DataCapturing/*.swift','DataCapturing/Model/*.swift'
  
  # s.resource_bundles = {
  #   'Cyface' => ['Cyface/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ReachabilitySwift', '~> 4.1.0'
end
