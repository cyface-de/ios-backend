#  Cyface iOS - SDK
image:https://app.bitrise.io/app/6f20b76474d7ea1a/status.svg?token=UIbKTKFzCOkyGWu3t8D3pQ[link="https://bitrise.io/"]

## Introduction

## Integration in your App

### Creating a `DataCapturingService`

To integrate the Cyface SDK for iOS into your own app you need to either create a `DataCapturingService` or a `MovebisDataCapturingService`.
This should look similar to:

```swift
// 1
let persistenceLayer = PersistenceLayer { persistence in
    // 2
    let authenticator = StaticAuthenticator()
    // 3
    let serverConnection = ServerConnection(apiURL: url, persistenceLayer: persistence, authenticator: authenticator)
    // 4
    let dcs = MovebisDataCapturingService(connection: serverConnection, sensorManager: sensorManager, updateInterval: interval, persistenceLayer: persistence)
}
```

1. Create a `PersistenceLayer` and wait asynchronously for CoreData to be ready, before you continue. Waiting asynchronously is optional, but you should to this to avoid weird errors occuring when you access a `PersistenceLayer` before it is initialized.
2. Create an `Authenticator` like explained under *Using an authenticator* below.
3. Create a `ServerConnection` for measurement data transmission. Provide the URL of a Cyface or Movebis server  endpoint together with the initialized `PersistenceLayer` instance and the `Authenticator`.
4. Finally create the `DataCapturingService` or `MovebisDataCapturingService` as shown, providing the required parameters.

### Using an Authenticator
The Cyface SDK for iOS transmits measurement data to a server. 
To authenticate with this server, the SDK uses an implementation of the `Authenticator`  class.
There are two `Authenticator` implementations available.

The `StaticAuthenticator` should be used if you have your own way of obtaining an authentication token.
It should be supplied with an appropriate JWT token prior to the first authentication call.

The `CredentialsAuthenticator` retrieves a JWT token from the server directly and tries to refresh that token, if it has become invalid.

### Getting the length of a track

The Cyface SDK for iOS is capable of providing the length of a track in meters.
To get access to this value you should either use the instance of `PersistenceLayer` that you have created, for the `DataCapturingService` or create a new one on demand.
Using that `PersistenceLayer` you can access the track length by loading a measurement, which looks similar to:

```swift
var trackLength:Double
persistenceLayer.load(measurementIdentifiedBy: identifier) { measurement, status in
    guard case .success = status, let measurement = measurement else {
        fatalError()     
    }

    trackLength = measurement.trackLength
}
```

Notice that this call is asynchronous.
If a synchronous call is required use for example a [`DispatchGroup`](https://developer.apple.com/documentation/dispatch/dispatchgroup).

## Building from Source
Contains swiftlint
See: https://github.com/realm/SwiftLint

## License
