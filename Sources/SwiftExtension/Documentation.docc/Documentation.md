# ``SwiftExtension``

Extensions to the Swift standard library plus core data structures and math utilities used by the rest of the package.

## Overview

SwiftExtension provides a small, dependency-light baseline: container types, interpolation helpers, numeric utilities, and targeted extensions to standard protocols and collections. It is intentionally narrow so other modules can import it without pulling in framework baggage. Extensions cover `Array`, `Dictionary`, `Optional`, `Result`, `String`, plus core collection and numeric protocols.

## Topics

### Collections

- ``StackProtocol``
- ``Stack``
- ``Pair``
- ``Node``
- ``LinkedList``
- ``Queue``
- ``FastQueue``
- ``Heap``
- ``PriorityQueue``
- ``HashedHeap``

### Builders

- ``DictionaryBuilder``
- ``makeDictionary(_:)``

### Math

- ``clamp(_:min:max:)``
- ``clamp(_:to:)-(_,ClosedRange<T>)``
- ``lerp(_:min:max:)->T``
- ``ilerp(_:min:max:)->T``
- ``greatestCommonDivisor(_:_:)``
- ``greatestCommonDivisor(_:)``
- ``leastCommonMultiple(_:_:)``
- ``lowestTerms(numerator:denominator:)``

### Debug

- ``debug_action(_:)``
- ``debug_print(_:separator:terminator:)``
- ``debug_print_async(_:separator:terminator:)``


### Ranges

- ``ClosedRange``
- ``Range``

### Guides

- <doc:CollectionsAndBuilders>
