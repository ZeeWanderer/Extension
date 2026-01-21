# View Utilities

Small SwiftUI helpers for layout, shadows, and capture.

## Overview

SwiftUIExtension adds a handful of view-level helpers that reduce boilerplate: frame helpers, `Shadow` for consistent styling, and a `screenShot` hook when you need to render a view tree to an image.

## Example

```swift
import SwiftUIExtension

Text("Preview")
    .shadow(data: Shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2))
```
