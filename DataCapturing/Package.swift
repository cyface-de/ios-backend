// swift-tools-version: 5.6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataCapturing",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DataCapturing",
            targets: ["DataCapturing"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // DataCompression Library to handle complicated ObjectiveC compression API.
        .package(name: "DataCompression", url: "https://github.com/mw99/DataCompression.git", from: "3.0.0"),
        // Alamofire handles the Network traffic.
        .package(name: "Alamofire", url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.1"),
        // Apple library to handle Protobuf conversion for transmitting files in the Protobuf format.
        .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),

        // Test Dependencies
        // Mocker provides functionality to Mock Network communication allowing us to test the data transfer layer.
        .package(name: "Mocker", url: "https://github.com/WeTransfer/Mocker.git", from: "2.5.5"),

        // Tools
        // Required to generated DocC documentation
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DataCapturing",
            dependencies: [
                .byName(name: "Alamofire"),
                .byName(name: "DataCompression"),
                .byName(name: "SwiftProtobuf"),
            ]),
        .testTarget(
            name: "DataCapturingTests",
            dependencies: ["DataCapturing", "Mocker"],
            exclude: ["Resources/README.md"],
            resources: [
                .process("Resources"),
            ]),
    ]
)
