// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "FileViewer",
	platforms: [
		.macOS(.v13),
		.iOS(.v16),
		.watchOS(.v8),
	],
	products: [
		.library(
			name: "FileViewer",
			targets: ["FileViewer"]),
	],
	dependencies: [
		.package(url: "https://github.com/ios-tooling/Suite.git", from: "1.0.139"),
	],
	targets: [
		.target(
			name: "FileViewer",
			dependencies: [
				.product(name: "Suite", package: "Suite"),
			]),
		.testTarget(
			name: "FileViewerTests",
			dependencies: ["FileViewer"]),
	]
)
