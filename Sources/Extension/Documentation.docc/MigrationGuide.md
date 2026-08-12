# Migration Guide

Move between major Extension releases by applying every section after the
version currently used by the client, in ascending order.

## Overview

This is the canonical cumulative migration guide for the package. It lives in
the umbrella `Extension` documentation because a major release can change more
than one module. Module guides may explain an API in more depth, but source and
behavior migrations belong here.

The cumulative guide starts with the transition from 15.x to the next major
release. Keep this section when later major releases are added so a client can
migrate through each boundary without consulting old generated documentation.

## Migrating from 15.x to 16.0

### Adopt Swift 6

Extension now compiles exclusively in the Swift 6 language mode. Use a Swift
6.1 or newer toolchain, as required by the package manifest, and remove any
dependency override that forces Extension itself into Swift 5 mode. Language
mode is selected per target, so a client target does not have to adopt Swift 6
merely because it imports Extension.

### Replace the legacy JSON loading globals

The nonthrowing `load_collection` and `load_object` overloads were removed.
They were tied to `Bundle.main`, duplicated decoding logic, printed or discarded
errors, and used snake-case production names.

Use `JSONCoding` and handle its errors explicitly:

```swift
let coding = JSONCoding()

let model = try coding.decode(
    Model.self,
    fromResource: "Model",
    in: .main
)
```

For an existing mutable value, assign the decoded result:

```swift
model = try coding.decode(Model.self, fromResource: "Model")
```

`JSONCoding.encode(_:)` and `decode(_:from:)` are synchronous.
`encodeAsync` and `decodeAsync` perform coding outside the caller's actor.
`encodingTask` and `decodingTask` start work immediately and return a task that
can be awaited after other work.

The unusable `SingleValueDecodingContainer` raw-representable dictionary
overload was removed. Continue using the `JSONDecoder` root overload for a
top-level keyed JSON object; synthesized model decoding continues to use the
`KeyedDecodingContainer` overload recursively.

### Update binary collection imports and constraints

`BinaryRepresentableCollection` and its `Data`, `Array`, and `Set` conveniences
moved from `AccelerateExtension` to `FoundationExtension`. Existing clients that
import only `AccelerateExtension` continue to see the API because that module
re-exports `FoundationExtension`.

Remove constraints and casts that treated `BinaryRepresentableCollection` or
`Set` as `AccelerateBuffer`. Those unrelated conformances were removed. Use the
collection's standard contiguous-storage APIs when raw storage access is needed.

### Replace removed ActorProtocol macros

`ActorProtocolExtension` and `ActorProtocolIgnore` were removed because Swift
rejects the arbitrary extension declarations they attempted to generate. Keep
using `ActorProtocol`; write any additional actor extension explicitly.

### Replace expired UIKit aliases

Replace both table-view and collection-view calls as follows:

```swift
// Removed
let cell: Cell = view.dequeueReusableCell(forIndexPath: indexPath)

// Current
let cell: Cell = view.dequeueReusableCell(for: indexPath)
```

### Replace expired logging aliases

Replace `messagePrefix` with `logScope`. Replace
`LogSubsystemProtocol.name` with `class_` when the unqualified type name is
needed, or with `subsystem` when the full logging subsystem identifier is
needed.

### Replace expired CoreGraphics clamp labels

Use the `Numeric2D` axis names shared by `CGPoint`, `CGSize`, and `CGVector`:

| Removed | Replacement |
| --- | --- |
| `value.clamped(dx:)` | `value.clamped(x:)` |
| `value.clamped(dy:)` | `value.clamped(y:)` |
| `value.clamped(dx:dy:)` | `value.clamped(x:y:)` |
| `value.clamped(width:)` | `value.clamped(x:)` |
| `value.clamped(height:)` | `value.clamped(y:)` |
| `value.clamped(width:height:)` | `value.clamped(x:y:)` |
| `clamp(value, dx:)` or `clamp(value, width:)` | `clamp(value, x:)` |
| `clamp(value, dy:)` or `clamp(value, height:)` | `clamp(value, y:)` |
| `clamp(value, dx:dy:)` or `clamp(value, width:height:)` | `clamp(value, x:y:)` |

### Replace expired SwiftUI compatibility modifiers

The package now targets iOS and Mac Catalyst 17, so the pre-iOS-15 compatibility
branches are outside its deployment range. Replace the removed methods with
their SwiftUI equivalents:

| Removed | Replacement |
| --- | --- |
| `compat_task` | `task` |
| `compat_overlay` | `overlay(alignment:content:)` |
| `compat_background` | `background(alignment:content:)` |
| `compat_mask` | `mask(alignment:_:)` |

### Review corrected behavior

- `Queue` copies now have independent value semantics.
- `HashedHeap` maintains its index map through construction and mutation and
  treats duplicate insertions as no-ops.
- Missing typed numeric `UserDefaults` values now return `nil`.
- GCD and LCM results are nonnegative and LCM divides before multiplying.
- Non-center SwiftUI rectangle anchors, empty cyclic schedules, router pop
  bounds, collection chunk sizes, and empty-string partial ranges no longer
  trap or produce invalid geometry.
- `ModelSnapshot` preserves nonoptional to-one relationship optionality in its
  generated public snapshot API. Remove obsolete optional unwrapping at affected
  call sites.
