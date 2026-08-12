# JSON Coding Guide

Encode and decode JSON synchronously, asynchronously, or as deferred task work.

## Synchronous coding

`JSONCoding` wraps preconfigured `JSONEncoder` and `JSONDecoder` instances and
propagates their errors:

```swift
struct Payload: Codable
{
    let id: Int
}

let coding = JSONCoding()
let data = try coding.encode(Payload(id: 42))
let payload = try coding.decode(Payload.self, from: data)
```

Synchronous methods execute completely on the calling thread. Use them when the
payload is small or the caller intentionally needs a blocking result.

Pass configured Foundation coders to keep date, data, key, floating-point, user
info, and output-formatting strategies together:

```swift
let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

let coding = JSONCoding(encoder: encoder, decoder: decoder)
```

Complete configuration before starting concurrent operations.

## Awaited asynchronous coding

Use `encodeAsync` and `decodeAsync` to keep synchronous Foundation coding work
off the caller's actor:

```swift
let data = try await coding.encodeAsync(payload)
let copy = try await coding.decodeAsync(Payload.self, from: data)
```

Values crossing this isolation boundary must be `Sendable`. The implementation
uses a detached task because Foundation's encoder and decoder expose synchronous,
CPU-bound methods. Cancellation is checked before and after each Foundation
operation. An encode or decode already in progress cannot be interrupted, but a
cancelled caller receives `CancellationError` instead of the completed value.

## Start now and await later

Task-returning variants are useful when synchronous code starts serialization
before another asynchronous step:

```swift
let task = coding.encodingTask(for: payload)

prepareRequestHeaders()

let body = try await task.value
```

The caller owns the returned task and can cancel it directly.

## Files and resources

File overloads combine data access and JSON coding. Writes are atomic by default:

```swift
try coding.encode(payload, to: fileURL)
let restored = try coding.decode(Payload.self, contentsOf: fileURL)
```

Bundle resources default to the `json` extension and throw
`JSONCodingError.resourceNotFound` when absent:

```swift
let bundled = try coding.decode(
    Payload.self,
    fromResource: "Payload",
    in: .main
)
```

Every file and resource operation also has an asynchronous or task-returning
counterpart.

## Raw-representable dictionary keys

Foundation normally encodes a dictionary whose key is not exactly `String` or
`Int` as an alternating array. `FoundationExtension` also supports decoding an
external keyed JSON object into a dictionary whose key is a raw-representable
type:

```swift
enum Field: String, Decodable
{
    case primary
    case secondary
}

let fields = try JSONDecoder().decode([Field: Int].self, from: data)
```

The matching `KeyedDecodingContainer` overload applies recursively to dictionary
properties in decoded models. This is intentionally a decoding feature; adding
a transparent `encode` overload conflicts with Foundation's generic encoder and
breaks synthesized `Encodable` overload resolution. General `JSONCoding`
round trips therefore retain Foundation's standard `Codable` representation.
