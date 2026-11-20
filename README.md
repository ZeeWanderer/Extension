# Extension

An extension of `Foundation`, `CoreGraphics`, `UIKit`, `SwiftUI` and `SpriteKit` frameworks I use across my projects.

Version 16 requires Xcode 27 or newer (Swift tools 6.4). The package supports
iOS 17, Mac Catalyst 17, and macOS 14 or newer. Individual APIs declare their
own availability.

Highlights:
- Lossy decoding utilities for resilient JSON parsing in `FoundationExtension`
- Synchronous, asynchronous, and deferred-task JSON coding in `FoundationExtension`
- Macro helpers in `MacrosExtension`
- Convenience APIs across the supported frameworks

See [Documentation](https://zeewanderer.github.io/Extension/documentation/)
for the cumulative migration guide and package-wide API conventions.

## Development

Apply the repository's pinned Swift formatter:

```sh
./format
```

Check formatting without changing files:

```sh
./format --lint
```

---
License: Unlicense
