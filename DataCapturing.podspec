# Copyright 2018 - 2021 Cyface GmbH
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

Pod::Spec.new do |s|
  s.name             = 'DataCapturing'
  s.version          = '11.1.0'
  s.summary          = 'Framework used to continuously capture data from all available sensors on an iOS device and transmit it to a Cyface-API compatible server.'

  s.description      = <<-DESC
This framework can be included by your App if you are going to capture sensor data and transmit that data to a Cyface-API server for further analysis.
                       DESC

  s.homepage              = 'https://cyface.de'
  # Podspecs do not support references to files in the parent folder.
  # So Podspec needs to be on same level as license
  s.license               = { :type => 'GPL', :file => 'LICENSE' }
  s.authors               = 'Cyface GmbH'
  s.source                = { :git => 'https://github.com/cyface-de/ios-backend.git', :tag => s.version.to_s }
  s.social_media_url      = 'https://twitter.com/CyfaceDE'

  s.platform	          = :ios, '12.4'
  s.ios.deployment_target = '12.4'
  s.swift_version         = '5.3'

  # It seems these files need to reside inside a folder DataCapturing (same name as framework).
  # This caused some headaches but should be fine with the current structure
  s.source_files = 'DataCapturing/Source/**/*{.h,.m,.swift}'
  s.resources = 'DataCapturing/Source/**/*{.xcdatamodeld,.xcdatamodel,.xcmappingmodel}'

  s.script_phase = { :name => 'Set version and build', :script => "#!/bin/bash\n\n# Determine plist path\nplist=${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}\n# Determine current version\nversion=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' \"$plist\")\n# Get date of last commit\ncommitDate=$(date -r `git log -1 --date=short --pretty=format:%ct` +%Y%m%d)\n# Get current date/time\nbuildDate=$(date +%Y%m%d%H%M)\n\n# Set display version to existing version + commitDate\n/usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString $version-$commitDate\" \"$plist\"  # Version number\n\n# Set build number to current date/time\n/usr/libexec/PlistBuddy -c \"Set :CFBundleVersion $buildDate\" \"$plist\"  # Build number\n\necho \"Version: $version-$commitDate\"\necho \"Build:   $buildDate\"\n" }

  s.frameworks = 'CoreData', 'CoreLocation', 'CoreMotion'
  
  # The following transitive dependencies are used by this project:
  # This one is used to handle network traffic like multipart requests
  s.dependency 'Alamofire', '~> 4.9.1'
  # A wrapper for the complicated ObjectiveC compression API.
  s.dependency 'DataCompression', '~> 3.6.0'

  # Podspecs do not support references to files in the parent folder.
  # So make sure tests are always located on the same level or below the podspec.
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'DataCapturing/Tests/**/*.swift'
    test_spec.resources = 'DataCapturing/Tests/**/*.sqlite'
  end


  s.app_spec 'Cyface' do |app_spec|
    app_spec.source_files = 'Example/Source/**/*.swift'
    app_spec.test_spec 'ExampleUnitTests' do |example_unit_test_spec|
      example_unit_test_spec.source_files = 'ExampleUnitTests/**/*.swift'
    end
  end

end
