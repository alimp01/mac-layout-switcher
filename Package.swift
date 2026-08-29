// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacLayoutSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        // Ядро: конвертер раскладок, буфер слова, шаблоны, детектор.
        // Компилируется и тестируется на Linux и macOS.
        .target(name: "SwitcherCore"),
        // macOS-приложение: исходники целиком под #if os(macOS),
        // на Linux target собирается в пустой executable и не мешает тестам.
        .executableTarget(
            name: "MacLayoutSwitcher",
            dependencies: ["SwitcherCore"]
        ),
        .testTarget(
            name: "SwitcherCoreTests",
            dependencies: ["SwitcherCore"]
        )
    ]
)
