# Changelog
This file contains the most important especially the breaking changes in between version.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0).
The versions adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html), as close as possible.

Since we did not use this format right from the start, early versions are not listed here.

## [6.0.1] - 2020-02-04
### Fixed
* Lifecycle should correctly restart now if implementing app crashed or was forced to shut down during a measurement
* eventType from Event class is not visible to implementing apps

## [6.0.0] - 2019-10-28
### Fixed
* Binary format for events file has used a 64 bit integer for the count of events instead of a 32 bit one. This should be fixed now

### Added
* Enable additional sensor data to be captured. Additional sensors are gyroscope and magnetometer. Data from these sensors is uploaded to a Cyface server as well.

## [5.0.0] - 2019-10-16
### Fixed
* Upload of measurement files to Cyface Server. This was producing a status code 500
* Missing documentation was added
* lint issues

### Added
* Change of transporation mode (modality) is now possible during a measurement via `DataCapturingService.changeModality(to:)`
* Method to load events by type and in the order they have occured to `PersistenceLayer`
* Method to delete events from the database via `PersistenceLayer`
* Method to count locations faster and more easily via `PersistenceLayer`
* Upload of events as a separate file to a Cyface server

### Changed
* Alamofire to version 4.9.0
* Modalities are no longer an enumeration but have been changed to be strings. This makes them configurable by the calling application

## [4.6.1] - 2019-08-07
### Info
* Compatible with the [Cyface Data Collector](https://github.com/cyface-de/data-collector) 4.0.0

### Added
* The type of the vehicle used to capture the data can now be transmitted to the server as a part of the multi part upload

## [4.6.0] - 2019-07-29
### Info
* Initial release before changelog

