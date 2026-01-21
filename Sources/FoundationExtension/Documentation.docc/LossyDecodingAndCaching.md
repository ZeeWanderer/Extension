# Lossy Decoding and Caching

Strategies for resilient decoding and lightweight in-memory caches.

## Overview

FoundationExtension provides two pragmatic tools: `@Lossy` for tolerant decoding of partially valid payloads, and `Cache`/`ObjectCache` wrappers over `NSCache` with a small, generic API.

## Example

```swift
import FoundationExtension

struct Payload: Codable
{
    @Lossy var ids: [Int]
}

let cache = Cache<String, Data>()
cache.insert(Data([0x1, 0x2]), forKey: "blob")
let cached = cache.value(forKey: "blob")
```
