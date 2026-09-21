# JSON Coding Guide

Encode and decode JSON synchronously, with structured concurrency, or through
an explicit task handle from synchronous code.

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
executes directly in the caller's task rather than creating a hidden task.
These entry points are explicitly `@concurrent`, so they continue to leave the
caller's actor with `NonisolatedNonsendingByDefault` enabled.
Foundation's encoder and decoder expose synchronous, CPU-bound methods, so the
async functions execute outside the caller's actor. Cancellation is checked
before and after each Foundation operation. An encode or decode already in
progress cannot be interrupted, but a cancelled caller receives
`CancellationError` instead of the completed value.

Use structured concurrency to overlap JSON coding with other asynchronous work:

```swift
async let firstData = coding.encodeAsync(firstPayload)
async let secondData = coding.encodeAsync(secondPayload)

let (first, second) = try await (firstData, secondData)
```

The `async let` child cannot escape its scope and cancellation follows the
parent task automatically.

## Start from synchronous code

Task-returning variants are an explicit unstructured-concurrency bridge when
synchronous code must start serialization without blocking:

```swift
let task = coding.detachedEncodingTask(for: payload)

prepareRequestHeaders()

let body = try await task.value
```

These variants create detached tasks. The caller owns the returned task's
lifetime and can cancel it directly. Prefer `async let` or a task group whenever
an asynchronous parent scope is available.
Awaiting a returned task's `.value` does not attach it to the awaiting task's
structured lifetime or propagate cancellation from that task.

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

Every file and resource operation also has a structured asynchronous or
explicit task-returning counterpart. Cancellation before a write prevents the
write from starting. Once a write begins it is allowed to finish, so a completed
side effect is not subsequently reported as cancellation.

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

let fields = try JSONCoding().decode([Field: Int].self, from: data)
```

`JSONCoding` provides the same raw-key decoding behavior for data, files, and
bundle resources through synchronous, structured asynchronous, and explicitly
detached entry points. The `JSONDecoder` root overload remains available, and
the matching `KeyedDecodingContainer` overload applies recursively to dictionary
properties in decoded models.

These decoders accept both the external keyed-object form and Foundation's
alternating-array representation. This remains intentionally a decoding feature;
adding a transparent `encode` overload conflicts with Foundation's generic
encoder and breaks synthesized `Encodable` overload resolution. Encoding and
same-type round trips therefore retain Foundation's standard `Codable`
representation.
