// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Elasticsearch",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Elasticsearch",
            targets: ["Elasticsearch"]),
        .library(
            name: "FluentElasticsearch",
            targets: ["FluentElasticsearch"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/vapor/database-kit", from: "1.2.0"),
        .package(url: "https://github.com/vapor/fluent", from: "3.0.0"),
        .package(url: "https://github.com/vapor/http", from: "3.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
//        .package(url: "https://github.com/vapor/console", from: "3.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Elasticsearch",
            dependencies: ["HTTP", "DatabaseKit", "SwiftyJSON"]),
        .target(
            name: "FluentElasticsearch",
            dependencies: ["Fluent", "SwiftyJSON", "Elasticsearch"]),
        .testTarget(
            name: "ElasticsearchTests",
            dependencies: ["Elasticsearch"]),
    ]
)
