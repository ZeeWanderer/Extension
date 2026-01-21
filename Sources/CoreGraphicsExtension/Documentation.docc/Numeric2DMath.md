# Numeric2D Math

Vector-like math helpers for CoreGraphics types.

## Overview

CoreGraphicsExtension formalizes 2D numeric protocols and adds interpolation helpers. The goal is to reduce boilerplate around `CGPoint`, `CGSize`, and `CGVector` math while keeping type constraints explicit.

## Example

```swift
import CoreGraphicsExtension

let start = CGPoint(x: 0, y: 0)
let end = CGPoint(x: 100, y: 50)
let mid: CGPoint = lerp(0.5, min: start, max: end)

let rect = union([CGRect(x: 0, y: 0, width: 10, height: 10),
                  CGRect(x: 5, y: 5, width: 20, height: 20)])
```
