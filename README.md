#  Cyface iOS - SDK
[![CI: Bitrise](https://app.bitrise.io/app/6f20b76474d7ea1a/status.svg?token=UIbKTKFzCOkyGWu3t8D3pQ)](link="https://bitrise.io/")
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Introduction

This is the Cyface SDK for iOS. It provides a framework you can use to continuously measure localized (i.e. annotated with GPS coordinates) sensor data from devices running iOS (i.e. iPhone).
It is mostly used to measure traffic data for different modalities, like walking, cycling or driving.
The framework is developed by the Cyface GmbH and mostly used to measure cycling behaviour with the purpose of improving the cycling infrastructure based on the measured data.

The framework provides three core features, which are *capturing data*, *accessing captured data for local display* and *transmitting captured data to a [Cyface server](https://github.com/cyface-de/data-collector)*.

The core concept used in this framework is the *Measurement*. A measurement is one sequence of locations and sensor data and usually associated with a purpose like commute from or to work.
A measurement might contain pauses and therefore is structured into several tracks.
There is an API to control the capturing lifecycle via the `DataCapturingService` class.
There is also an API to access captured data via the `PersistenceLayer` class.
The `ServerConnection` class finally is responsible for transmitting captured data to a Cyface server.

## Migration Notes
- [4.0.0](Documentation/4.0.0-MigrationGuid.md)

## Integration in your App

### Creating a `DataCapturingService`

To integrate the Cyface SDK for iOS into your own app you need to either create a `DataCapturingService` or a `MovebisDataCapturingService`.
This should look similar to:

```swift
// 1
import CoreMotion
...
// 2
let persistence = try PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy())
// 3
let authenticator = StaticAuthenticator()
// 4
let serverConnection = ServerConnection(apiURL: url, persistenceLayer: persistence, authenticator: authenticator)
// 5
let sensorManager = CMMotionManager()
// 6
let updateInterval = 100
// 7
let savingInterval = 10
// 8
let handler = handler
// 9
let dcs = try MovebisDataCapturingService(connection: serverConnection, sensorManager: sensorManager, updateInterval: updateInterval, savingInterval: savingInterval, persistenceLayer: persistence, eventHandler: handler)
```

1. Import Apples *CoreMotion* framework, to be able to create a motion manager.
2. Create a `PersistenceLayer` and provide a distance calculation strategy. Currently there is only the `DefaultDistanceCalculationStrategy` which uses the integrated distance calculation between locations as provided by Apple.
3. Create an `Authenticator` like explained under *Using an authenticator* below.
4. Create a `ServerConnection` for measurement data transmission. Provide the URL of a Cyface or Movebis server  endpoint together with the initialized `PersistenceLayer` instance and the `Authenticator`.
5. Create `CMMotionManager` from the CoreMotion framework. This is responsible for capturing sensor data from your device.
6. Set a sensor data update interval in Hertz. The value 100 for example means that your sensors are going to caputre 100 values per second. This is the maximum for most devices. If you use higher values CoreMotion will tread them as 100. The value 100 is also the default if you do not set this value.
7. Create a saving interval in seconds. The value 10 for example means that your data is saved to persistent storage every 10 seconds. This also means your currently captured measurement is updated every 10 seconds. Values like the measurement length are updated at this point as well. If you need to update your UI frequently you should set this to a low value. This however also puts a higher load on your database.
8. Provide a handler for events occuring during data capturing. Possible events are explained below.
9. Finally create the `DataCapturingService` or `MovebisDataCapturingService` as shown, providing the required parameters.

### Using an Authenticator
The Cyface SDK for iOS transmits measurement data to a server. 
To authenticate with this server, the SDK uses an implementation of the `Authenticator`  class.
There are two `Authenticator` implementations available.

The `StaticAuthenticator` should be used if you have your own way of obtaining an authentication token.
It should be supplied with an appropriate JWT token prior to the first authentication call.

The `CredentialsAuthenticator` retrieves a JWT token from the server directly and tries to refresh that token, if it has become invalid.

### Getting a track of locations
As explained above each measurement contains one or several tracks. 
On each use of the `pause` and `resume` lifecycle methods a new track is created. 
To access the locations from a track, do something like the following.

```swift
let persistenceLayer = try PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy())
persistenceLayer.context = persistenceLayer.makeContext()
let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)
if let tracks = measurement.tracks {
    if let locations = tracks[0].locations {
	for location in locations {
            print(\(location))
        }
    }
}
```

### Getting the length of a measurement

The Cyface SDK for iOS is capable of providing the length of a measurement in meters.
To get access to this value you should either use the instance of `PersistenceLayer` that you have created, for the `DataCapturingService` or create a new one on demand.
Using that `PersistenceLayer` you can access the track length by loading a measurement, which looks similar to:

```swift
persistenceLayer.context = persistenceLayer.makeContext()
let measurement = try persistenceLayer.load(measurementIdentifiedBy: identifier) 
let trackLength = measurement.trackLength
```

## API Documentation
[See](docs/index.html)

## Building from Source
Contains swiftlint
See: https://github.com/realm/SwiftLint

## License
Copyright 2017 Cyface GmbH

This file is part of the Cyface SDK for iOS.

The Cyface SDK for iOS is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Cyface SDK for iOS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
