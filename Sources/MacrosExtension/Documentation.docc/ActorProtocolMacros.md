# Actor Protocol Macros

Derive actor-facing protocols and glue code from protocol definitions.

## Example

```swift
import MacrosExtension

@ActorProtocol
public protocol DataService: Sendable {
    var context: Int { get }
    func getContext0() -> Int
    func getContext1() -> Int
}

@ActorProtocolExtension(name: "DataService")
struct DataServiceImpl: DataService {
    var context: Int { 0 }
    override public func getContext0() -> Int { context }
    @ActorProtocolIgnore
    override public func getContext1() -> Int { context }
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

extension DataService {
    func getContext0() -> Int {
        context
    }
    func getContext1() -> Int {
        context
    }
}

extension DataServiceActor {
    func getContext0() -> Int {
        context
    }
}
```
