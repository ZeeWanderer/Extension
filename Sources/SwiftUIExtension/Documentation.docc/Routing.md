# Routing

Build a SwiftUI router with ready-made path operations while retaining control
over storage, presentation, view construction, and application-specific
navigation behavior.

## Choose Path Storage

All routers adopt ``RouterProtocol``. The base protocol deliberately does not
prescribe storage.

For a single `NavigationStack`, adopt ``SinglePathRouterProtocol``:

```swift
@MainActor
@Observable
final class AppRouter: SinglePathRouterProtocol {
    typealias Destination = AppDestination

    var path: [Destination] = []
}
```

For several equivalent keyed paths, adopt ``DictionaryRouterProtocol``:

```swift
@MainActor
@Observable
final class AppRouter: DictionaryRouterProtocol {
    typealias Destination = AppDestination

    enum PathID: Hashable {
        case home
        case profile
    }

    static let defaultPathID: PathID? = .home
    var paths: [PathID: [Destination]] = [:]
}
```

Use ``RouterProtocol`` directly when paths do not fit either representation.
Implement ``RouterProtocol/path(for:)`` and
``RouterProtocol/withPath(_:_:)`` to map identifiers to stored tab paths,
nested sheet stacks, presentation roots, or queues. Override
``RouterProtocol/resolvePathID(_:)`` when an omitted path should select the
currently active tab or presentation.
Declare `static let defaultPathID: PathID? = nil` for a custom router without
a fixed fallback. Single-path routers receive `.main` automatically.

`withPath` returns `false` when an identifier has no mutable storage. Default
navigation operations then report failure without claiming that a mutation
occurred.

## Render Destinations Directly

Adopt ``RouterViewProvider`` when a router or destination owns view creation.
The associated view type supports `some View`, so this path does not require
`AnyView`, a model protocol, or a registration table.

```swift
extension AppRouter: RouterViewProvider {
    @ViewBuilder
    func view(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> some View {
        switch destination {
        case .home:
            HomeView()
        case let .profile(id):
            ProfileView(id: id)
        }
    }
}
```

Install the provider on a stack with
`navigationDestinations(from:pathID:requester:userInfo:)`.
The router can override ``RouterProtocol/destinationContext(for:pathID:requester:userInfo:)``
to add destination-specific construction data.

## Use a View Registry

Adopt ``RouterViewRegistryProtocol`` when destinations are split into separate
view and model types:

```swift
@MainActor
final class AppRouter: DictionaryRouterProtocol, RouterViewRegistryProtocol {
    // Path declarations omitted.

    static let views: [any RouterDestinationView<Destination>.Type] = [
        HomeDestinationView.self,
        ProfileDestinationView.self,
    ]

    static let viewTypes = computeViewTypes()
}
```

``RouterDestinationModel`` and ``RouterDestinationView`` receive one
``RouterDestinationContext`` containing the resolved path identifier,
requester, and application-defined `userInfo`. This keeps the stable registry
API from gaining a new positional argument whenever an application needs more
construction context.

Duplicate registrations trap by default. Set
``RouterViewRegistryProtocol/viewRegistrationConflictPolicy`` to
``RouterViewRegistrationConflictPolicy/keepFirst`` or
``RouterViewRegistrationConflictPolicy/keepLast`` when composition makes a
deterministic override preferable. Override
``RouterViewRegistryProtocol/missingDestinationView(for:context:)`` for an
application-specific fallback.

## Customize Navigation Semantics

The default implementation provides push, pop, pop-to, exact and case-only
queries, peek, and first-or-last replacement. The mutating operations are
protocol requirements, not statically dispatched helpers. Override their full
requirement signatures for behavior such as allocating a sheet identifier,
incrementing a destination instance, or dismissing a presentation root.

For example, a sheet router can override `push(_:to:options:)`, create a new
presentation, and return its concrete path identifier. Generic callers still
receive that identifier. Convenience overloads without every argument forward
through the requirement and preserve the override.

Use these smaller hooks when the default mutation is otherwise suitable:

- ``RouterProtocol/rootDestination(for:on:)`` makes `popToExisting` recognize
  a root represented by an empty path. It receives both the proposed
  destination and path, supporting either destination families or per-tab
  roots.
- ``RouterProtocol/shouldPerformNavigation(_:on:)`` can reject a request.
- ``RouterProtocol/routerDidPerform(_:)`` receives successful and rejected
  default operations for logging, analytics, or breadcrumbs.

``RouterNavigationEvent`` records path depth before and after an in-place
mutation, not copies of the paths. This keeps observation from forcing
copy-on-write during every push. Inspect the router in the hook when current
destination details are needed.

## Define Destination Comparison

``RouterDestination`` uses the entire destination as `flat` by default. This
is sufficient when case-only comparison is unnecessary:

```swift
enum Destination: RouterDestination {
    case details(id: Int)
}
```

Define a separate `Flat` type and `flat` mapping when operations must compare a
case without its associated values. The `@RouterDestination` macro generates
that mapping by default. Use `flatName:` to rename it, or
`generateFlat: false` to retain exact comparison or provide a custom mapping.
