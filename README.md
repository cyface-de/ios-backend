#  Cyface iOS - SDK
image:https://app.bitrise.io/app/6f20b76474d7ea1a/status.svg?token=UIbKTKFzCOkyGWu3t8D3pQ[link="https://bitrise.io/"]

## Introduction

## Integration in your App
To integrate the Cyface SDK for iOS into your own app you need to either create a `DataCapturingService` or a `MovebisDataCapturingService`.
This should look similar to:

```swift
let authenticator = StaticAuthenticator()
let serverConnection = ServerConnection(apiURL: url, persistenceLayer: persistenceLayer, authenticator: authenticator)
let dcs = MovebisDataCapturingService(connection: serverConnection, sensorManager: sensorManager, updateInterval: interval, persistenceLayer: persistenceLayer)
```

### Using an authenticator
The Cyface SDK for iOS transmits measurement data to a server. 
To authenticate with this server, the SDK uses an implementation of the `Authenticator`  class.
There are two `Authenticator` implementations available.

The `StaticAuthenticator` should be used if you have your own way of obtaining an authentication token.
It should be supplied with an appropriate JWT token prior to the first authentication call.

The `CredentialsAuthenticator` retrieves a JWT token from the server directly and tries to refresh that token, if it has become invalid.

## Building from Source
Contains swiftlint
See: https://github.com/realm/SwiftLint

## License
