// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "integration_test", path: "/Users/simon/fvm/versions/master/packages/integration_test/ios/integration_test"),
        .package(name: "sqlite3_flutter_libs", path: "/Users/simon/src/sqlite3.dart/sqlite3_flutter_libs/darwin/sqlite3_flutter_libs")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "integration-test", package: "integration_test"),
                .product(name: "sqlite3-flutter-libs", package: "sqlite3_flutter_libs")
            ]
        )
    ]
)
