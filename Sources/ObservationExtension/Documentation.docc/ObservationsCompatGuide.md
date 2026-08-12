# Observations Compatibility

Use transactional observation before the system `Observations` type is available.

## Overview

`ObservationsCompat` follows the public behavior of `Observation.Observations` while supporting the package's iOS 17, Mac Catalyst 17, and macOS 14 deployment targets. On version 26 and newer systems it delegates observation and cancellation to `Observation.Observations`; on older systems it uses the package's compatibility implementation. It is separate from `Observe_` and does not change that API's behavior.

The sequence emits its current value immediately. It then waits for any `@Observable` dependency read by the producer to change and emits the value at the end of that transaction. A pending iteration finishes with `nil` when its task is cancelled.

```swift
import Observation
import ObservationExtension

@Observable @MainActor
final class Counter
{
    var value = 0
}

@MainActor
func printChanges(to counter: Counter) async throws
{
    let values = ObservationsCompat {
        counter.value
    }

    for try await value in values {
        print("value =", value)
    }
}
```

Use ``ObservationsCompat/untilFinished(_:)`` when the producer needs to terminate the sequence explicitly. A thrown producer error also terminates its iterator and is rethrown from `next()`.

The compatibility name intentionally avoids colliding with the system type when both modules are imported. Call sites can keep using `ObservationsCompat` across supported system versions without conditional availability branches.
