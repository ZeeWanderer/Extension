# Test organization

Every library module has a correspondingly named test target and directory. A
test belongs to the narrowest module whose public API it exercises. Tests use
ordinary imports for public contracts, so access-level and
source-compatibility regressions fail while compiling a client of that module.
Narrow implementation-invariant tests may use `@testable` when the invariant
cannot be observed through public API, such as proving that repeated capacity
eviction reuses a disk inventory instead of rescanning the directory.

- `<Module>Tests` contains that module's public behavior contracts.
- `ExtensionTests` verifies representative umbrella-module re-exports only.
- `ExtensionMacroTests` contains exact implementation expansion snapshots and
  compiler integration fixtures, and runs in the macOS-only macro scheme.
- `ExtensionPerformanceTests` mirrors the source-module directories and
  contains realistic hot-path measurements. Run these in release mode when
  recording or comparing baselines:

  ```sh
  swift test -c release --filter PerformanceTests
  ```

The shared `Extension` scheme runs the module suites in Debug. The shared
`Extension Release Tests` scheme runs those same suites plus performance tests
in Release. Macro implementation snapshots remain isolated in `Extension Macro
Tests (macOS)` so selecting an iOS Simulator does not cross the host-only macro
test boundary.

The compile-time contracts catch changes to APIs they exercise. Before a
release, compare the complete exported surface with the previous release tag or
commit:

```sh
swift package diagnose-api-breaking-changes <previous-release> --products Extension
```

## Module coverage

Every source target is covered. Public library targets have at least one
client-style public API contract; the implementation-only macro target has
exact expansion tests:

| Module | Representative coverage |
| --- | --- |
| `Macros` | Direct expansion snapshots for every registered macro implementation; real compiler diagnostics and Debug/Release gating for `debug_view` |
| `MacrosExtension` | Compiled generated-API and macro-usage tests |
| `SwiftExtension` | Collections, math, builders, and input-safety contracts |
| `FoundationExtension` | JSON coding, raw-key dictionaries, unknown-case raw values, binary representation, lossy decoding, caching, localization, and defaults |
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

## View diagnostic macro coverage

`DebugViewMacroTests` checks expansion structure, conservative exclusions, and
unchanged output when `DEBUG` is absent or the compiler cannot report its build
configuration. `DebugViewPublicAPITests` compiles the public macro and checks
concrete types, evaluation order, short-circuiting, autoclosures, and branches.

`DebugViewCompilerTests` invokes the selected host compiler on resource fixtures
in `ExtensionMacroTests/Fixtures`. Intentionally invalid files are not ordinary
test-module sources. These tests check real diagnostics at the default solver
budget and a small controlled budget, corrected code with and without the
macro, both `@ViewBuilder` attribute orders, and the consuming target's DEBUG
condition independently of the plugin configuration. Processes have a safety
timeout; elapsed time is not a performance assertion. Compiler improvements to
the original default-budget diagnostic are accepted.

Run `swift test --filter DebugView`, or use the macOS macro scheme in Xcode.
Run the same filter with `-c release` to exercise a release-built macro plugin.
The harness finds the plugin beside the active test products; an unusual build
layout can set `EXTENSION_MACRO_PLUGIN_PATH` to its executable path. The host
compiler tests are never run inside an iOS Simulator.

## Cache coverage

The Foundation test target keeps Cache tests together by subsystem while
separating the kinds of failure they diagnose:

| Suite | Contract |
| --- | --- |
| `CacheCapacityPolicyTests` | Store-agnostic bounds, stable LRU planning, recent-use protection, hard pressure, and custom units |
| `CacheConfigurationTests` | Public values, routes, ownership, validation, and normalization |
| `CacheDispatcherTests` | Store dispatch, promotion, rollback, disk persistence, and cache-wide barriers |
| `CacheConcurrencyTests` | Same-key read/write semantics and mixed synchronous/asynchronous access |
| `CacheStabilityTests` | Deterministic model comparison, expiration, and ordered failure reporting |
| `CacheDiskStoreTests` | Payload boundaries, corruption, trimming, reopening, and concurrent file access |
| `CacheMaintenanceTests` | Store selection, throttling, cancellation, allocated disk capacity, age/expiration, and soft/hard eviction |
| `DiskCacheMaintenancePolicyTests` | Adaptive sizing, independent maintenance cadence, edge-triggered watermarks, indexed capacity eviction, and sparse namespace traversal safety |
| `CacheStressTests` | High contention, key-gate churn, dynamic routes, cancellation, capacity/write races, and `removeAll()` races |
| `SparseCacheTests` | Range math, persistence, generations, namespace isolation, positional I/O, and overlapping/disjoint access |
| `SparseCacheFailureTests` | Failed-write recovery without advertising incomplete ranges |
| `P_CacheRangeGateTests` | Interval-aware reader/writer exclusion invariants |
| `CachePerformanceTests` | Capacity planning, memory lookup/mutation, mixed async load, disk round trips, maintenance scans, and tier promotion |
| `SparseCachePerformanceTests` | Concurrent disjoint writes and range reads |

Useful focused runs are:

```sh
swift test --filter 'FoundationExtensionTests\.(Cache|DiskCache|SparseCache|P_Cache)'
swift test -c release --filter 'FoundationExtensionTests\.(Cache|DiskCache|SparseCache|P_Cache)'
swift test --sanitize=thread --filter 'FoundationExtensionTests\.(Cache|DiskCache|SparseCache|P_Cache)'
swift test -c release --filter 'ExtensionPerformanceTests\.(CachePerformanceTests|SparseCachePerformanceTests)'
```

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

### Initial Cache performance reference

Recorded on 13 August 2026 on the same machine and toolchain:

| Contract | Work per measured iteration | Mean | Relative deviation |
| --- | --- | ---: | ---: |
| Synchronous memory lookup | 100K reads across 4,096 keys | 60 ms | 0.18% |
| Synchronous memory mutation | 100K writes across 4,096 keys | 77 ms | 0.44% (retired instructions: 0.09%) |
| Concurrent async memory lookup | 100K reads across 100 workers | 160 ms | 3.04% |
| Concurrent mixed async memory load | 100K operations across 100 workers, one write per eight operations | 153 ms | 0.24% |
| Concurrent disk round trip | 256 writes and reads of 16 KiB across 32 workers | 27 ms | 1.19% |
| Disk-to-memory tier promotion | 512 independent promotions of 4 KiB | 11 ms | 3.20% |
| Capacity eviction planning | Stable LRU plan across 10K weighted candidates | 11 ms | 0.46% |
| Disk maintenance scan | Scan 1,000 valid entries with eight file operations in flight | 19 ms | 1.67% |

Sparse-cache references were recorded on 1 September 2026 on the same machine
and toolchain:

| Contract | Work per measured iteration | Mean | Relative deviation |
| --- | --- | ---: | ---: |
| Concurrent disjoint sparse writes | 256 independent 32 KiB writes | 8 ms | 2.63% |
| Concurrent sparse range reads | 1,024 independent 16 KiB reads across 64 workers | 21 ms | 0.90% |

Fixed behavior remains expressed as a direct public contract; the suite contains
no accepted failures.
