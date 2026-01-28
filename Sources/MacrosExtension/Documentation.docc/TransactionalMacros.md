# Transactional Macro

Wrap model mutations in a `ModelContext.transaction` block, with optional re-entrancy handling.

## Example

```swift
import MacrosExtension
import SwiftData

final class Store {
    let modelContext: ModelContext

    @Transactional(retval: 0)
    func increment(_ value: Int) -> Int {
        value + 1
    }
}
```

## Expansion (simplified)

```swift
final class Store {
    let modelContext: ModelContext

    func __original_increment(_ value: Int) -> Int {
        value + 1
    }

    func increment(_ value: Int) -> Int {
        if TransactionContext.isActive {
            return __original_increment(value)
        } else {
            return modelContext.transaction { __original_increment(value) } ?? 0
        }
    }
}
```

Notes:
- If you pass `ctx:` or `keyPath:`, the macro uses that context instead of `modelContext`.
- For optional contexts, the macro falls back to calling the original function when the context is `nil`.
