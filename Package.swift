// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanMyKeyboard",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CleanMyKeyboard", targets: ["CleanMyKeyboard"]),
        .executable(name: "CleanMyKeyboardSelfCheck", targets: ["CleanMyKeyboardSelfCheck"])
    ],
    targets: [
        .target(name: "KeyboardBlockerCore"),
        .executableTarget(
            name: "CleanMyKeyboard",
            dependencies: ["KeyboardBlockerCore"]
        ),
        .executableTarget(
            name: "CleanMyKeyboardSelfCheck",
            dependencies: ["KeyboardBlockerCore"]
        )
    ]
)
