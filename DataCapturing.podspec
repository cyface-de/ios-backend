# Copyright 2018 Cyface GmbH
#
# This file is part of the Cyface SDK for iOS.
#
# The Cyface SDK for iOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The Cyface SDK for iOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.

#
# Be sure to run `pod lib lint Cyface.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DataCapturing'
  s.version          = '6.1.0'
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
  s.swift_version    = '5.0'

  s.source_files = 'DataCapturing/**/*{.h,.m,.swift}'
  s.resources = [ 'DataCapturing/**/*{.xcdatamodeld,.xcdatamodel,.xcmappingmodel}' ]
  # s.preserve_paths = 'DataCapturing/Model/CyfaceModel.xcdatamodeld'
  # s.requires_arc = true

  # s.resource_bundles = {
  #   'Cyface' => ['Cyface/Assets/*.png']
  #    'DataCapturing' => ['DataCapturing/Model/CyfaceModel.xcdatamodeld']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreData', 'CoreLocation', 'CoreMotion'
  # s.framework = 'CoreData'
  
  # The following transitive dependencies are used by this project:
  # This one is used to handle network traffic like multipart requests
  s.dependency 'Alamofire', '~> 4.9.0'
  # A wrapper for the complicated ObjectiveC compression API.
  s.dependency 'DataCompression', '~> 3.4.0'

  s.test_spec 'DataCapturingTests' do |test_spec|
    test_spec.source_files = 'DataCapturingTests/**/*.swift'
    #test_spec.dependency 'OCMock' # This dependency will only be linked with your tests.
  end

end
