// swift-tools-version: 5.6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
 * Copyright 2019-2023 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import PackageDescription

let package = Package(
    name: "DataCapturing",
    platforms: [
        .iOS(.v14),
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
