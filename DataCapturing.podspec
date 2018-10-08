#
# Be sure to run `pod lib lint Cyface.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DataCapturing'
  s.version          = '1.2.0'
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

  s.platform	     = :ios, '11.0'

  s.source_files = 'DataCapturing/*.swift','DataCapturing/Model/*.swift','DataCapturing/Cyface/*.swift','DataCapturing/Movebis/*.swift'
  s.resources = 'DataCapturing/Model/CyfaceModel.xcdatamodeld'
  
  # s.resource_bundles = {
  #   'Cyface' => ['Cyface/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  
  # The following transitive dependencies are used by this project:
  # This one is used to handle network traffic like multipart requests
  s.dependency 'Alamofire', '~> 4.6'
  # A wrapper for the complicated ObjectiveC compression API.
  s.dependency 'DataCompression', '~> 2.0.1'

  s.test_spec 'DataCapturingTests' do |test_spec|
    test_spec.source_files = 'DataCapturingTests/*.swift'
    #test_spec.dependency 'OCMock' # This dependency will only be linked with your tests.
  end

end
