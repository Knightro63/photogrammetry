// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "photogrammetry",
  platforms: [
    .macOS(.v12),
    .iOS(.v17)
  ],
  products: [
    .library(name: "photogrammetry", targets: ["photogrammetry"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "photogrammetry",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ],
      path: "Sources" // Adjust this to match your folder structure (e.g., "Classes" or "Sources")
    )
  ]
)
