# Test organization

The suite is split by purpose:

- `ExtensionTests` contains public behavior contracts. These tests use ordinary imports, never `@testable`, so source compatibility and access-level regressions fail during compilation.
- `ExtensionMacroTests` contains exact expansion snapshots and compiled public macro-usage contracts.
- `ExtensionPerformanceTests` contains realistic hot-path measurements. Run these in release mode when recording or comparing baselines:

  ```sh
  swift test -c release --filter PerformanceTests
  ```

The compile-time contracts catch changes to APIs they exercise. Before a release, compare the complete exported surface with the previous release tag or commit:

```sh
swift package diagnose-api-breaking-changes <previous-release> --products Extension
```

## Module coverage

Every source target has at least one client-style public API contract:

| Module | Representative coverage |
| --- | --- |
| `Macros` | Direct expansion snapshots for every registered macro implementation |
| `MacrosExtension` | Compiled generated-API and macro-usage tests |
| `SwiftExtension` | Collections, math, builders, and input-safety contracts |
| `FoundationExtension` | JSON coding, raw-key dictionaries, binary representation, lossy decoding, localization, and defaults |
| `osExtension` | Public logging protocol defaults |
| `ObservationExtension` | Transactional observations and observable defaults |
| `AccelerateExtension` | Public full convolution and re-exported binary APIs |
| `CoreGraphicsExtension` | Geometry, two-dimensional arithmetic, and binary representation |
| `UIKitExtension` | Colors and view-controller traversal |
| `SpriteKitExtension` | Module import on macOS; scene and composite screenshot accessors on UIKit platforms |
| `SwiftUIExtension` | Colors, routing, geometry, and timeline safety |
| `GeneralExtensions` | Runtime configuration consistency |
| `Extension` | Representative umbrella-module re-exports |

This is a minimum surface check, not a claim that every public declaration has
behavioral coverage. The API-diff gate remains responsible for detecting
unexercised source-compatible surface changes.

Performance tests intentionally avoid hard-coded wall-clock assertions, which are unreliable across developer and CI hardware. Store the first accepted measurements as Xcode performance baselines, then review relative regressions there.

## Initial local performance reference

Recorded on 12 August 2026 with a release build on a 10-core Apple M4 MacBook Pro with 16 GB RAM, macOS 27.0, and Apple Swift 6.3.3. These values are a review reference, not portable pass/fail limits.

| Contract | Work per measured iteration | Mean | Relative deviation |
| --- | --- | ---: | ---: |
| Full convolution | 3 convolutions of 1M `Float` values with a 31-tap kernel | 3 ms CPU | 6.31% (retired instructions: 0.12%) |
| Binary array round trip | 10 round trips of 2.5M `Int64` values | 13 ms CPU | 8.74% (retired instructions: 0.67%) |
| Set round trip | 5 round trips of 100K `Int64` values | 27 ms CPU | 0.57% (retired instructions: 0.01%) |
| Stable set encoding | 3 sorted encodes of 100K `Int64` values | 22 ms CPU | 0.94% (retired instructions: 0.09%) |
| JSON coding round trip | 3 round trips of 10K structured values | 89 ms CPU | 1.63% (retired instructions: 0.01%) |
| Fast queue throughput | 20 enqueue/drain cycles of 250K values | 18 ms | 1.35% |
| Hashed heap build/drain | Build and drain 100K values | 553 ms CPU | 0.41% |
| Rectangle union | 100 unions of 100K rectangles | 48 ms | 0.39% |
| Linked-list queue throughput | 3 enqueue/drain cycles of 100K values | 108 ms | 1.49% |
| Numeric 2D arithmetic | 100 passes over 250K points | 17 ms | 0.69% |
| Queue copy-on-write | Copy, mutate, and drain 100K values | 38 ms | 1.16% |

For the Accelerate and allocation-heavy binary cases, retired instruction count
was more stable than elapsed CPU time and is the better first signal when
comparing this machine's runs.

Fixed behavior remains expressed as a direct public contract; the suite contains
no accepted failures.
