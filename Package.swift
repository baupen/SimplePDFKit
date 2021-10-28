// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SimplePDFKit",
	platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "SimplePDFKit",
            targets: ["SimplePDFKit"]
		),
    ],
    dependencies: [
		.package(url: "https://github.com/juliand665/HandyOperators", from: "2.0.0"),
		.package(url: "https://github.com/juliand665/CGeometry", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "SimplePDFKit",
            dependencies: ["HandyOperators", "CGeometry"]
		),
    ]
)
