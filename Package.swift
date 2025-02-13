// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var sources = [
    "src/llama.cpp",
    "src/llama-adapter.cpp",
    "src/llama-arch.cpp",
    "src/llama-chat.cpp",
    "src/llama-batch.cpp",
    "src/llama-context.cpp",
    "src/llama-cparams.cpp",
    "src/llama-grammar.cpp",
    "src/llama-hparams.cpp",
    "src/llama-impl.cpp",
    "src/llama-kv-cache.cpp",
    "src/llama-mmap.cpp",
    "src/llama-model.cpp",
    "src/llama-model-loader.cpp",
    "src/llama-quant.cpp",
    "src/llama-sampling.cpp",
    "src/llama-vocab.cpp",
    "src/unicode.cpp",
    "src/unicode-data.cpp",
    "ggml/src/ggml.c",
    "ggml/src/ggml-alloc.c",
    "ggml/src/ggml-backend.cpp",
    "ggml/src/ggml-backend-reg.cpp",
    "ggml/src/ggml-quants.c",
    "ggml/src/ggml-threading.cpp",
    "ggml/src/gguf.cpp",
    "ggml/src/ggml-cpu/ggml-cpu.c",
    "ggml/src/ggml-cpu/ggml-cpu.cpp",
    "ggml/src/ggml-cpu/ggml-cpu-aarch64.cpp",
    "ggml/src/ggml-cpu/ggml-cpu-hbm.cpp",
    "ggml/src/ggml-cpu/ggml-cpu-quants.c",
    "ggml/src/ggml-cpu/ggml-cpu-traits.cpp"
]

var resources: [Resource] = []
var linkerSettings: [LinkerSetting] = []
var cSettings: [CSetting] =  [
    .unsafeFlags(["-Wno-shorten-64-to-32", "-O3", "-DNDEBUG"]),
    .unsafeFlags(["-fno-objc-arc"]),
    .headerSearchPath("ggml/src"),
    .headerSearchPath("ggml/include"),
    .headerSearchPath("ggml/src/ggml-cpu"),
    // NOTE: NEW_LAPACK will required iOS version 16.4+
    // We should consider add this in the future when we drop support for iOS 14
    // (ref: ref: https://developer.apple.com/documentation/accelerate/1513264-cblas_sgemm?language=objc)
    // .define("ACCELERATE_NEW_LAPACK"),
    // .define("ACCELERATE_LAPACK_ILP64")
    .define("GGML_USE_CPU"),
]

#if canImport(Darwin)
sources.append("ggml/src/ggml-common.h")
sources.append("ggml/src/ggml-metal/ggml-metal.m")
resources.append(.process("ggml/src/ggml-metal/ggml-metal.metal"))
linkerSettings.append(.linkedFramework("Accelerate"))
cSettings.append(
    contentsOf: [
        .define("GGML_USE_ACCELERATE"),
        .define("GGML_USE_METAL"),
    ]
)
#endif

let package = Package(
    name: "LlamaKit",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
   ],
    products: [
        .library(
            name: "LlamaKit",
            targets: ["LlamaKit"]),
        .library(name: "llama", targets: ["llama"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LlamaKit",
            dependencies: ["llama"],
            path: "Sources/LlamaKit",
            swiftSettings: [
                .unsafeFlags(["-Onone"], .when(configuration: .release))
            ]
        ),
        .target(
            name: "llama",
            path: "Sources/llama.cpp",
            exclude: [
                "build",
                "cmake",
                "examples",
                "scripts",
                "models",
                "tests",
                "CMakeLists.txt",
                "Makefile",
                "ggml/src/ggml-metal/ggml-metal.metal"
            ],
            sources: sources,
            resources: resources,
            publicHeadersPath: "spm-headers",
            cSettings: cSettings,
            swiftSettings: [  // Disable optimization because model generate random response in release mode.
                .unsafeFlags(["-Onone"], .when(configuration: .release))
            ],
            linkerSettings: linkerSettings
        ),
        .testTarget(
            name: "LlamaKitTests",
            dependencies: ["LlamaKit"]
        )
    ],
    cxxLanguageStandard: .cxx17
)
