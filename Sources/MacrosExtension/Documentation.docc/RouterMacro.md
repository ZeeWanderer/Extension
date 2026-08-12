# Router Macros

Infer common router conformances and generate case-only destination mappings
without preventing custom storage, rendering, or navigation behavior.

## Router

`@Router` inspects the declaration's existing members:

- A `path` property adds `SinglePathRouterProtocol` conformance.
- A `paths` property adds `DictionaryRouterProtocol` conformance.
- Neither property adds the storage-independent `RouterProtocol` conformance.
- A static `views` registry adds `RouterViewRegistryProtocol` conformance and
  generates `viewTypes` when it is not already declared.
- A `view(for:context:)` implementation adds `RouterViewProvider` conformance.

Apply `@Router` to a class. Routers are reference types isolated to the main
actor by `RouterProtocol`.

The macro never creates stored path state. This keeps it compatible with
`@Observable`, `ObservableObject`, custom nested presentation storage, and
application-specific initialization.

```swift
@MainActor
@Observable
@Router
final class AppRouter {
    typealias Destination = AppDestination

    var path: [Destination] = []

    @ViewBuilder
    func view(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> some View {
        destination.view
    }
}
```

Explicitly declare any router protocol when member-name inference would not
express the intended design. The macro preserves that choice and only adds a
missing rendering conformance when applicable.

## Router Destination

`@RouterDestination` adds `RouterDestination` conformance and normally
generates a nested `Flat` enum plus the `flat` mapping:

```swift
@RouterDestination
enum Destination {
    case details(id: Int)
    case settings
}
```

Rename the generated type when `Flat` conflicts with an existing declaration:

```swift
@RouterDestination(flatName: "Kind")
enum Destination {
    case details(id: Int)
    case settings
}
```

Suppress generation when exact destination comparison is sufficient or when a
hand-written mapping is needed:

```swift
@RouterDestination(generateFlat: false)
enum Destination {
    case details(id: Int)
}
```

Without a custom mapping, `RouterDestination` uses `Self` as its `Flat` type.
