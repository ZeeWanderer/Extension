# Actor Protocol Macros

Derive an actor-facing companion protocol from a synchronous protocol definition.

The generated protocol preserves all original requirements and inheritance.
Function requirements that are not already asynchronous gain `async`; properties,
subscripts, and associated types are copied without being discarded or reordered.

## Example

```swift
import MacrosExtension

@ActorProtocol
public protocol DataService: Sendable {
    var context: Int { get }
    func getContext0() -> Int
    func getContext1() -> Int
}

struct DataServiceImpl: DataService {
    let context: Int

    func getContext0() -> Int { context }
    func getContext1() -> Int { context }
}

actor ActorDataServiceImpl: DataServiceActor {
    let context: Int

    func getContext0() -> Int { context }
    func getContext1() -> Int { context }
}
```

## Expansion

```swift
public protocol DataService: Sendable {
    var context: Int { get }
    func getContext0() -> Int
    func getContext1() -> Int
}

public protocol DataServiceActor: Sendable, Actor {
    var context: Int { get }
    func getContext0() async -> Int
    func getContext1() async -> Int
}

```

Synchronous actor implementations satisfy the generated asynchronous function
requirements. Access through `DataServiceActor` still requires `await` because
the companion protocol inherits from `Actor`.

## Migration

`@ActorProtocolExtension` and `@ActorProtocolIgnore` were removed. The former
attempted to generate extensions of types other than the declaration it was
attached to, which Swift's macro system rejects in real client compilation.
Move those method bodies directly into conforming types or ordinary protocol
extensions.
