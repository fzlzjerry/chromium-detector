// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "chromium-detector",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "chromium-detector", targets: ["chromium-detector"])
    ],
    targets: [
        .executableTarget(
            name: "chromium-detector",
            path: "Sources"
        )
    ]
) 