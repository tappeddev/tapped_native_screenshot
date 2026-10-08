// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tapped_native_screenshot",
    platforms: [.iOS("13.0")],
    products: [
        .library(
            name: "tapped-native-screenshot",
            targets: ["tapped_native_screenshot"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "tapped_native_screenshot",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
