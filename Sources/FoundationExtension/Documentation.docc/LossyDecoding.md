# Lossy Decoding

Decode valid collection elements while reporting or discarding malformed ones.

## Overview

Use `@Lossy` when one malformed element should not reject an otherwise useful
payload. Configure a ``LossyDecodingReporter`` when the discarded elements
need to be logged or measured.

```swift
import FoundationExtension

struct Payload: Codable
{
    @Lossy var ids: [Int]
}
```

Lossy decoding is an explicit model decision. Keep ordinary `Decodable`
properties for values whose absence or corruption must reject the payload.
