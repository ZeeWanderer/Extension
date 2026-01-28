# CustomStringConvertibleEnum Macro

Generate `CustomStringConvertible` and `CustomDebugStringConvertible` for enums.

## Example

```swift
import MacrosExtension

@CustomStringConvertibleEnum
enum State: Hashable {
    case loading
    case failed(message: String)
}
```

## Expansion

```swift
enum State: Hashable {
    case loading
    case failed(message: String)
}

extension State: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .loading:
            return "loading"
        case .failed(let message):
            return "failed(\\(message))"
        }
    }
    public var debugDescription: String {
        switch self {
        case .loading:
            return "loading"
        case .failed(let message):
            return "failed(\\(message))"
        }
    }
}
```
