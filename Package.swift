// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "KokoroSwift",
  platforms: [
    .iOS(.v18), .macOS(.v15)
  ],
  products: [
    .library(
      name: "KokoroSwift",
      // Static linkage keeps MLX's generic Swift symbols available to release builds.
      type: .static,
      targets: ["KokoroSwift"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.29.1"),
    // .package(url: "https://github.com/mlalma/eSpeakNGSwift", from: "1.0.1"),
    .package(
      url: "https://github.com/Jon-Schneider/MisakiSwift",
      branch: "jsc/2026-06-08--static-package-product"
    ),
    .package(
      url: "https://github.com/Jon-Schneider/MLXUtilsLibrary.git",
      branch: "jsc/2026-06-08--static-package-product"
    )
  ],
  targets: [
    .target(
      name: "KokoroSwift",
      dependencies: [
        .product(name: "MLX", package: "mlx-swift"),
        .product(name: "MLXFast", package: "mlx-swift"),
        .product(name: "MLXNN", package: "mlx-swift"),
        .product(name: "MLXRandom", package: "mlx-swift"),
        .product(name: "MLXFFT", package: "mlx-swift"),
        // .product(name: "eSpeakNGLib", package: "eSpeakNGSwift"),
        .product(name: "MisakiSwift", package: "MisakiSwift"),
        .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")
      ],
      resources: [
       // Reference config.json directly (not the enclosing `Resources/` folder) so it
       // lands at the bundle root. Declaring the directory — via either `.copy` or
       // `.process` — reproduces the `Resources/` subdirectory inside the product bundle.
       // Deep (macOS/Mac Catalyst) bundles tolerate that, but on iOS it yields a shallow
       // bundle with a `Resources/` folder next to a top-level Info.plist, which `codesign`
       // rejects: "bundle format unrecognized, invalid, or unsuitable". A flat layout is
       // valid on every platform.
       .process("../../Resources/config.json")
      ]
    ),
    .testTarget(
      name: "KokoroSwiftTests",
      dependencies: ["KokoroSwift"]
    ),
  ]
)
