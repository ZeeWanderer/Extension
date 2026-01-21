# Binary Buffer IO

Read and write contiguous numeric buffers safely.

## Overview

`BinaryRepresentableCollection` exposes a buffer-backed view of values for Accelerate-style APIs. The extension on `BinaryRepresentable` adds convenience initializers and a `data` property to serialize and validate buffers.

## Example

```swift
import AccelerateExtension

let samples: [Float] = [0.1, 0.2, 0.3]
let data = samples.data
let restored = [Float](data: data)
```
