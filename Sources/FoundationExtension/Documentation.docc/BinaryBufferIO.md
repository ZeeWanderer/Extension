# Binary Buffer IO

Read and write validated, compact binary collections.

## Overview

`BinaryRepresentableCollection` stores the native, fixed-stride memory of its
elements back-to-back without a collection header. The element count is
inferred from the payload byte count. This preserves the existing compact
buffer shape while rejecting partial elements.

The implementation uses Swift's native contiguous-storage access when
available and otherwise creates a temporary `ContiguousArray`. It does not
depend on Accelerate or expose unrelated buffer conformances.

## Example

```swift
import FoundationExtension

let samples: [Float] = [0.1, 0.2, 0.3]
let data = samples.data
let restored = [Float](validating: data)
```

Use `init(validating:)` or `Data.saferLoad()` when the buffer may be too short
or contain a partial collection element. Validation only checks whether the
bytes have the shape needed to load the requested type; it does not validate
semantic invariants of the resulting value.

## Buffer format

An array payload is the collection's native contiguous element storage in array
order. There is no magic, version, or element-count header. Empty collections
encode as empty data. The payload is intended to be loaded as the same element
and collection types under a compatible ABI.

A set uses its current iteration order. That order is deliberately not part of
the contract: encoding and then decoding preserves set membership, but equal
sets are not required to produce byte-identical payloads.

When reproducible set bytes are needed, provide a strict total ordering:

```swift
let identifiers: Set<UInt64> = [30, 10, 20]
let stableData = identifiers.stableData(sortedBy: <)
let restored = Set<UInt64>(validating: stableData)
```

Equal sets produce equal sorted payloads when the same ordering and compatible
native element layout are used.

## Native representation contract

`BinaryRepresentable` is optimized for fast same-type round trips. Its bytes
retain the type's native layout, padding, and endianness. `CGFloat` delegates to
`CGFloat.NativeType`, so its representation follows the platform's actual
`Float` or `Double` backing type.

Use ``SafeBinaryRepresentable`` for custom types to have the compiler verify
that they are `BitwiseCopyable`. Bytes are not a portable persistence or
interchange format. The caller is responsible for loading data as the type that
produced it and for ensuring layout compatibility.
