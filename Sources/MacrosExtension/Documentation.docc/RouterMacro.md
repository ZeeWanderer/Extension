# Router Macro

Generate a cached `viewTypes` map and add ``RouterProtocol`` conformance when missing.

## Example

```swift
import MacrosExtension
import SwiftUIExtension

@Router
final class AppRouter: RouterProtocol {
    enum PathID: Hashable { case main }
    typealias Destination = AppDestination

    static let defaultPathID: PathID = .main
    static let views: [any RouterDestinationView<Destination>.Type] = [
        LoginView.self,
        ProfileView.self,
    ]

    var paths: [PathID: [Destination]] = [:]
}
```

## Expansion

```swift
final class AppRouter: RouterProtocol {
    static let viewTypes = computeViewTypes()
}

extension AppRouter: RouterProtocol {}
```
