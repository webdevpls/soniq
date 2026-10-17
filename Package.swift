// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Soniq",
    platforms: [.macOS("14.2")],
    targets: [
        .executableTarget(name: "Soniq", path: "Sources/Soniq")
    ]
)
