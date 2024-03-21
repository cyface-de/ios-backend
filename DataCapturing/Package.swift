// swift-tools-version: 5.6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
 * Copyright 2019-2024 Cyface GmbH
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
        .iOS(.v15),
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
        .package(url: "https://github.com/mw99/DataCompression.git", from: "3.0.0"),
        // Apple library to handle Protobuf conversion for transmitting files in the Protobuf format.
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
        // Library for handling OAuth Login Process
        .package(url: "https://github.com/openid/AppAuth-iOS.git", .upToNextMajor(from: "1.6.2")),

        // Test Dependencies
        // Mocker provides functionality to Mock Network communication allowing us to test the data transfer layer.
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.5.5"),

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
                "DataCompression",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "AppAuth", package: "AppAuth-iOS"),
            ],
            exclude: ["Support/Info.plist"],
            resources: [
                .process("Model/Migrations/V3toV4/V3toV4.xcmappingmodel"),
                .process("Model/CyfaceModel.xcdatamodeld"),
                .process("Model/Migrations/V10toV11/V10toV11.xcmappingmodel"),
                .process("Model/Migrations/V7toV8/V7toV8.xcmappingmodel"),
            ]),
        .testTarget(
            name: "DataCapturingTests",
            dependencies: ["DataCapturing", "Mocker"],
            exclude: ["Resources/README.md", "Info.plist"],
            resources: [
                .process("Resources"),
            ]),
    ]
)
