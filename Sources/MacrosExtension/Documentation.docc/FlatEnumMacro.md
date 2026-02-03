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

## Custom Name

Use `name` to control the generated flat enum name, or `generateName: false` to generate `Flat`.

```swift
@FlatEnum(name: "Flat")
enum Route {
    case detail(id: Int)
    case settings
}
```

```swift
@FlatEnum(generateName: false)
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

## Expansion (Custom Name)

```swift
enum Route {
    case detail(id: Int)
    case settings

    public enum Flat: Hashable {
        case detail
        case settings
    }

    public var flat: Flat {
        switch self {
        case .detail:
            return .detail
        case .settings:
            return .settings
        }
    }
}
```
