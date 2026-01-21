# Observation Streams

Bridge Observation state to async sequences.

## Overview

ObservationExtension provides `Observe_` and `MainActorObserve_` to expose changes from `Observable` models as async sequences. This is useful when you want a pull-based, cancellable consumer without manual publisher wiring.

## Example

```swift
import ObservationExtension

@Observable final class Counter
{
    var value: Int = 0
}

let counter = Counter()
for await next in Observe_(counter, keyPath: \.value) {
    print("value =", next)
}
```
