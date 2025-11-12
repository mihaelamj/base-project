// swift-tools-version: 6.0

import PackageDescription

// -------------------------------------------------------------

// MARK: Products

// -------------------------------------------------------------

let baseProducts: [Product] = [
    .singleTargetLibrary("SharedModels"),
]

#if os(iOS) || os(macOS)
let appleOnlyProducts: [Product] = [
    .singleTargetLibrary("AppColors"),
    .singleTargetLibrary("AppTheme"),
    .singleTargetLibrary("SharedViews"),
    .singleTargetLibrary("AuthFeature"),
    .singleTargetLibrary("AppFeature"),
    .singleTargetLibrary("AppFont"),
    .singleTargetLibrary("BetaSettingsFeature"),
    .singleTargetLibrary("DemoAppFeature"),
    .singleTargetLibrary("SharedComponents"),
    .singleTargetLibrary("Components"),
    .singleTargetLibrary("AppComponents"),
    .singleTargetLibrary("AllComponents"),
]
#else
let appleOnlyProducts: [Product] = []
#endif

// Always expose PlaybookFeature so Xcode shows the scheme
let allProducts = baseProducts + appleOnlyProducts + [
    .singleTargetLibrary("PlaybookFeature"),
]

// -------------------------------------------------------------

// MARK: Dependencies (updated versions)

// -------------------------------------------------------------

let deps: [Package.Dependency] = [
    // apple-only deps (only referenced by apple-only targets, safe on Linux CI)
    .package(url: "https://github.com/krzysztofzablocki/KZFileWatchers.git", from: "1.0.0"),
    .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.2.4"),
    .package(url: "https://github.com/AvdLee/Roadmap.git", branch: "main"),
    .package(url: "https://github.com/playbook-ui/playbook-ios", from: "0.4.0"),
]

// -------------------------------------------------------------

// MARK: Targets

// -------------------------------------------------------------

let targets: [Target] = {
    // ---------- Shared Models ----------
    let sharedModelsTarget = Target.target(
        name: "SharedModels",
        dependencies: []
    )
    let sharedModelsTestsTarget = Target.testTarget(
        name: "SharedModelsTests",
        dependencies: ["SharedModels"]
    )
    let modelTargets = [
        sharedModelsTarget,
        sharedModelsTestsTarget,
    ]

    let apiTargets: [Target] = []

    // ---------- Apple-only UI / Components ----------
    #if os(iOS) || os(macOS)
    // ---------- Foundation: AppColors (zero dependencies) ----------
    let appColorsTarget = Target.target(
        name: "AppColors",
        dependencies: []
    )

    let sharedComponentsTarget = Target.target(
        name: "SharedComponents",
        dependencies: [
            .product(name: "Inject", package: "Inject"),
            .product(name: "KZFileWatchers", package: "KZFileWatchers"),
        ]
    )

    let componentsTarget = Target.target(
        name: "Components",
        dependencies: ["SharedComponents"],
        resources: [.process("components.json")]
    )

    let appComponentsTarget = Target.target(
        name: "AppComponents",
        dependencies: ["Components", "AppTheme", "AppFont"],
        resources: [.process("Resources")]
    )

    let allComponentsTarget = Target.target(
        name: "AllComponents",
        dependencies: ["Components", "AppComponents"]
    )

    let appThemeTarget = Target.target(
        name: "AppTheme",
        dependencies: ["AppColors", "AppFont"]
    )

    let sharedViewsTarget = Target.target(
        name: "SharedViews",
        dependencies: [
            "AppTheme",
            "AppFont",
            .product(name: "Inject", package: "Inject"),
        ]
    )

    let authFeatureTarget = Target.target(
        name: "AuthFeature",
        dependencies: ["SharedModels", "SharedViews", "AppTheme", "AppFont"]
    )

    let appFeatureTarget = Target.target(
        name: "AppFeature",
        dependencies: ["SharedModels", "SharedViews", "AuthFeature", "AppFont"]
    )

    let appFontTarget = Target.target(
        name: "AppFont",
        dependencies: [],
        resources: [.process("Fonts")]
    )

    let betaSettingsFeatureTarget = Target.target(
        name: "BetaSettingsFeature",
        dependencies: [
            "SharedModels",
        ]
    )

    let demoAppFeatureTarget = Target.target(
        name: "DemoAppFeature",
        dependencies: [
            "SharedModels",
            "BetaSettingsFeature",
        ]
    )
    #endif

    // ---------- PlaybookFeature (scheme visible everywhere; links Playbook only on iOS) ----------
    let playbookTarget = Target.target(
        name: "PlaybookFeature",
        dependencies: [
            "Components",
            "AppComponents",
            "SharedModels",
            .product(name: "Inject", package: "Inject"),
            .product(
                name: "Playbook",
                package: "playbook-ios",
                condition: .when(platforms: [.iOS])
            ),
            .product(
                name: "PlaybookUI",
                package: "playbook-ios",
                condition: .when(platforms: [.iOS])
            ),
        ]
    )

    // Collect UI/component targets
    #if os(iOS) || os(macOS)
    let componentTargets: [Target] = [
        sharedComponentsTarget,
        componentsTarget,
        appComponentsTarget,
        allComponentsTarget,
    ]

    let uiTargets: [Target] = [
        appColorsTarget,
        appThemeTarget,
        sharedViewsTarget,
        authFeatureTarget,
        appFeatureTarget,
        appFontTarget,
        betaSettingsFeatureTarget,
        demoAppFeatureTarget,
        playbookTarget, // in uiTargets as requested
    ]
    #else
    let componentTargets: [Target] = []
    let uiTargets: [Target] = [playbookTarget]
    #endif

    return modelTargets + apiTargets + componentTargets + uiTargets
}()

// -------------------------------------------------------------

// MARK: Package

// -------------------------------------------------------------

let package = Package(
    name: "Main",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: allProducts,
    dependencies: deps,
    targets: targets
)

// -------------------------------------------------------------

// MARK: Helper

// -------------------------------------------------------------

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
