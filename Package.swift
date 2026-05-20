// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "micpause",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "micpause",
            path: "Sources/micpause"
        )
    ]
)
