// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KillPort",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KillPort", targets: ["KillPort"])
    ],
    targets: [
        .executableTarget(
            name: "KillPort",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
