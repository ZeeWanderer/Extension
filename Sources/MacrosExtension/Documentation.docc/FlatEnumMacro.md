# FlatEnum Macro

Generate a flat enum mirror for case identification.

## Example

```swift
import MacrosExtension

@FlatEnum
enum Route {
    case detail(id: Int)
    case settings
}
```

## Expansion

```swift
enum Route {
    case detail(id: Int)
    case settings

    public enum FlatRoute: Hashable {
        case detail
        case settings
    }

    public var flat: FlatRoute {
        switch self {
        case .detail:
            return .detail
        case .settings:
            return .settings
        }
    }
}
```
