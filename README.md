#  Cyface iOS - SDK
[![CI: Bitrise](https://app.bitrise.io/app/45ec21fd3b5a664b/status.svg?token=aE1ZWjYUkjxhAtYMX8bcCg)](https://bitrise.io/)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-blue.svg)](https://swift.org)

## Introduction

This is the Cyface SDK for iOS. It provides a framework you can use to continuously measure localized (i.e. annotated with GPS coordinates) sensor data from devices running iOS (i.e. iPhone).
It is mostly used to measure traffic data for different modalities, like walking, cycling or driving.
The framework is developed by the Cyface GmbH and mostly used to measure cycling behaviour with the purpose of improving the cycling infrastructure based on the measured data.

The framework provides three core features, which are *capturing data*, *accessing captured data for local display* and *transmitting captured data to a [Cyface server](https://github.com/cyface-de/data-collector)*.

The core concept used in this framework is the *Measurement*. 
A measurement is one sequence of locations and sensor data and usually associated with a purpose like commute from or to work.
A measurement might contain pauses and therefore is structured into several tracks.
There is an API to control the capturing lifecycle via the `DataCapturingService` class.
There is also an API to access captured data via the `PersistenceLayer` class.
The `ServerConnection` class is responsible for transmitting captured data to a Cyface server, while the Synchronizer makes sure this happens at convenient times and in regular intervals.

## Integration in your App

### Permissions

To use the Cyface SDK permissions to capture the users location while using the app and additionally in the background are required.
These permissions have to be declared as part of the App using the Cyface SDK.

How to allow background location updates is described in the [Apple Developer Documentation](https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/handling_location_events_in_the_background).

Asking for the proper location capturing permissions is described in the [Apple Developer Documentation](https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services) as well. 
The App using the Cyface SDK is only required to provide the proper entries in the Info.plist.
The code to ask for the proper permissions is executed by the SDK the first time it wants to fetch locations.
This usually happens on the first call to `start()`.
An App using the Cyface SDK requires at least "Location When In Use Usage Description" and "Location Always and When In Use Usage Description".

### Setup an Application

To store and retrieve data it is necessary to initialize the Cyface CoreDataStack.
You should do this as early as possible during your application lifecycle.
The most convenient place is inside your Applications `AppDelegate.application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool` method.
There you should call:

```swift
// 1
import DataCapturing
// 2
import CoreData
// 3
let manager = CoreDataManager()
// 4
guard let bundle = Bundle(for: type(of: manager)) else {
    fatalError()
}
// 5
manager.setup(bundle: bundle) {
    // 6
}
```

1. Import the *Cyface SDK*
2. Import the *CoreData* Framework
3. Create the *CoreData* stack in the form of a `CoreDataManager`. 
   Usually there should be only one instance of `CoreDataManager`. 
   You may optionally provide the store type and a `CoreDataMigrator`. 
   The store type should be an `NSSQLiteStoreType` (default) in production and might be an `NSInMemoryStoreType` in a test environment. 
   Please have a look at that classes documentation if you need to change the type of the storage for example.
4. Get a handle on the bundle the `CoreDataManager` belongs to.
5. Call setup on the `CoreDataManager`.
   If the `CoreDataManager` encounters an old data store it will migrate this data store to the current version. 
   If there is much data to convert, this can take some time and probably should be wrapped into a background thread. 
   **Be especially careful to avoid calling the `setup(bundle:, completionClosure:)` method on different threads concurrently. 
   This might leave your data storage in a corrupted state or at least crash your app.** 
6. When the setup of the `CoreDataManager` was successfully completed this callback closure is called.
   You should use it to continue with your application execution and for example present your main UI now.

### Creating a `DataCapturingService`

As explained above before using any data capturing the integrating App must have the appropriate permissions to use location tracking in the background.
See the Apple documentation about background location updates for more information.
The must also be a `manager` instance of type `CoreDataManager` (see last section).

To integrate the Cyface SDK for iOS into your own app you need to either create a `DataCapturingService` or a `MovebisDataCapturingService`.
This should look similar to:

```swift
// 1
import CoreMotion
// 2
import DataCapturing
...
// 3 
let sensorManager = CMMotionManager()
// 4
let updateInterval = 100
// 5
let savingInterval = 10
// 6
let handler = handler
// 7
let dcs = try MovebisDataCapturingService(sensorManager: sensorManager, updateInterval: updateInterval, savingInterval: savingInterval, dataManager: manager, eventHandler: handler)
```

1. Import Apples *CoreMotion* framework, to be able to create a motion manager.
2. Import the *Cyface SDK*, to be able to create a `DataCapturingService`.
3. Create `CMMotionManager` from the *CoreMotion* framework. This is responsible for capturing sensor data from your device.
4. Set a sensor data update interval in Hertz. The value 100 for example means that your sensors are going to capture 100 values per second. This is the maximum for most devices. If you use higher values CoreMotion will tread them as 100. The value 100 is also the default if you do not set this value.
5. Create a saving interval in seconds. The value 10 for example means that your data is saved to persistent storage every 10 seconds. This also means your currently captured measurement is updated every 10 seconds. Values like the measurement length are updated at this point as well. If you need to update your UI frequently you should set this to a low value. This however also puts a higher load on your database.
6. Provide a handler for events occuring during data capturing. Possible events are explained below.
7. Finally create the `DataCapturingService` or `MovebisDataCapturingService` as shown, providing the required parameters.

### The Data Capturing Lifecycle

The lifecycle of capturing a measurement is controlled by the four methods `start(inMode:)`, `pause()`, `resume()` and `stop()`.
They may be called in arbitrary order and will do as their name promises.

#### Setting and Changing Transportation Modes

The mode of transporation used to capture a measurement must be provided to the `start(inMode:)` method.
This is a simple string that is transferred as is to the server.
Typical transporation modes are "BICYCLE", "CAR" and "MOTORBIKE".

To change the transportation mode during a measurement, call `changeModality(to:)`.
For example call `dataCapturingService.changeModality(to: "CAR")`, to change the used transportation mode to a car.

#### Configuring a DataCapturingService

The `DataCapturingService` tries to get as many updates from a devices geo location sensor as possible.
This usually means it will receive one update per second.
If your UI does some heavy work on each update, you probably would like to receive fewer of them.
This can be controlled by setting the `DataCapturingService.locationUpdateSkipRate` to an appropriate value.
With a value of 2 for example it will only report every second update.
Notice however that internally it will still run with the highest possible update rate.

### Getting the currently captured measurement

If there is an active data capturing process - after a call to `DataCapturingService.start()` or  `DataCapturingService.resume()`, you can access the current measurement via:

```swift
if let currentMeasurementIdentifier = dcs.currentMeasurement?.identifier {
    let currentMeasurement = persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
    // Use the measurement
}
```

### Getting Track information from a measurement

Each measurement is organized into multiple tracks, which are split if the `DataCapturingService.pause()` and  `DataCapturingService.resume()` is called.
Each track contains an ordered list of geo locations.
Accessing this information to display it on the screen should follow the pattern below:

```swift
do {
    let persistenceLayer = PersistenceLayer(onManager: manager)
    persistenceLayer.context = persistenceLayer.makeContext()
    let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurement.identifier)

    guard let tracks = measurement.tracks?.array as? [Track] else {
        fatalError()
    }

    for track in tracks {
        guard let locations = track.locations?.array as? [GeoLocationMO] else {
            fatalError()
    }

    guard !locations.isEmpty else {
        os_log("No locations to display!")
        continue
    }

    // Transform the location model objects from the database to a thread safe representation.
    var localLocations = [GeoLocation]()
    for location in locations {
        localLocations.append(GeoLocation(latitude: location.lat, longitude: location.lon, accuracy: location.accuracy, speed: location.speed, timestamp: location.timestamp))
    }

    DispatchQueue.main.async { [weak self] in
        guard let self = self else {
            return
        }
        // Draw or refresh the UI.
    }
} catch {
    os_log("Unable to load locations!")
}
```
**ATTENTION:** Notice that all locations have been copied to new data objects. 
This is necessary, as *CoreData* objects are not thread safe and will loose all data upon usage on a different thread. 
You need to do this with all *CoreData* model objects before using them in your app. 
*CoreData* model objects currently are `MeasurementMO`, `Event`, `Track` and `GeoLocationMO`.

### Getting the length of a measurement

The Cyface SDK for iOS is capable of providing the length of a measurement in meters.
To get access to this value you should either use the instance of `PersistenceLayer` that you have created, for the `DataCapturingService` or create a new one on demand.
Using that `PersistenceLayer` you can access the track length by loading a measurement, which looks similar to:

```swift
persistenceLayer.context = persistenceLayer.makeContext()
let measurement = try persistenceLayer.load(measurementIdentifiedBy: identifier) 
let trackLength = measurement.trackLength
```

### Getting a cleaned track

The Cyface SDK for iOS is capable of providing a track where locations with too much noise are cleaned away.
Currently these are locations with an accuracy above 20.0 meters or a speed below 1 m/s (3.6 km/h) or above 100 m/s (360 km/h). 
This is currently hard coded into the SDK but might change in a future release.

```swift
let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
persistenceLayer.context = persistenceLayer.makeContext()
let measurement = persistenceLayer.load(measurementIdentifiedBy: identifier)
guard let track = measurement.tracks?.array.last as? Track else {
    fatalError()
}
let cleanTrack = try oocut.loadClean(track: track)
```

The `cleanTrack` is an array of `GeoLocationMO` instances.
This array is not to be used on a different thread. Before using it you should copy all its values to main memory (or know how to use faults in CoreData).

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
let persistenceLayer = PersistenceLayer(onManager: manager)
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

### Getting a log of lifecycle events

If you need to know about past start, pause, resume and stop events you may retrieve them, by loading a measurement from a `PersistenceLayer`.
The measurement provides the events as follows:

```swift
let loadedEvents = loadedMeasurement.events?.array as? [Event]
```

The list is ordered by the occurence time of the events.
Each event provides a type, best retrieved from `Event.typeEnum` and the time of its occurrences as an `NSDate`.

### Continuous synchronization

To keep measurements synchronized without user interaction, the Cyface SDK provides the `Synchronizer`.
It is advised to create a synchronizer after successful authentication.
Do not forget to call `Synchronizer.activate()`.
This starts a background process, that monitors the devices connectivity state and watches for an active WiFi connection.
If one is found, synchronization for all unsynchronized measurements is executed.
Creating a synchronizer should look something like:

```swift
// 1.
let url = URL(string: "http://localhost/api")!
// 2.
let serverConnection = ServerConnection(apiURL: url, authenticator: authenticator, onManager: manager)
// 3.
let synchronizer = try Synchronizer(
// 4.
coreDataStack: manager, 
// 5.
cleaner: AccelerationPointRemovalCleaner(), 
// 6.
serverConnection: serverConnection) { event, status in 
	// Handle .synchronizationFinished event for example by checking status for .success or .failure
}
```

1. Create the URL where your server is ready to receive data.
2. Create a `ServerConnection` from the URL created in the previous step and add an authenticator and a manager as described above.
3. Create the `Synchronizer` based on the following parameters.
4. Preferrably use the same `CoreDataManager` as described under setting up the `DataCapturingService`.
5. Create a `Cleaner` which cleanes the database after successful synchronization.
6. Provide the `ServerConnection` as created in step 2.

## API Documentation
[See](docs/index.html)

## Building from Source
Contains swiftlint
See: https://github.com/realm/SwiftLint

### Creating the documentation
* Install Jazzy
* Call `jazzy` from the terminal in the root folder.

## Releasing a new Version
* Always work on a new branch based on main conforming to the pattern "release-<major>.<minor>.<fix>_PROJ-TASKNUMBER
* Increase Version for DataCapturing Target and DataCapturing.podspec
* If a new release to the AppStore should happen also increase version for example App
* Create PR into release branch
* Check Version and Since Tags on all added and changed files
* Build Documentation
* Check Readme (Is it up to date with the most recent changes?)
* After approval merge into release and tag the merge commit with `git tag - <major>.<minor>.<fix>` appropriately
* Make the tag to a release on Github and explain the changes following "Keeping a Changelog"


## License
Copyright 2017 - 2021 Cyface GmbH

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
