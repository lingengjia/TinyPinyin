// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TinyPinyin",
    products: [
        .library(
            name: "TinyPinyin",
            targets: ["TinyPinyin"]
        ),
    ],
    targets: [
        .target(
            name: "TinyPinyin"
        ),
    ]
)
