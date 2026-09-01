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

## Tolerate new raw-value cases

Use ``UnknownCaseCodable`` for a raw-value enumeration when a service may add
cases before the application is updated:

```swift
enum Status: String, UnknownCaseCodable
{
    case active
    case inactive
    case unknown
}
```

A recognized value decodes normally. An unrecognized string decodes as
`.unknown`, allowing its containing model to remain usable. A value of the
wrong raw type still throws rather than hiding a malformed payload.

The fallback does not retain the original raw value. Re-encoding writes the
sentinel case's raw value. Use a custom `RawRepresentable` value type instead
when the application must display, log, or round-trip the unknown token.
