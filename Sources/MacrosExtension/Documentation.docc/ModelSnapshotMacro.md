# ModelSnapshot Macro

Generate snapshot types for SwiftData models.

## Example

```swift
import MacrosExtension
import SwiftData

@ModelSnapshot
@Model
final class Item {
    var title: String = ""

    @SnapshotIgnore
    @Relationship
    var related: Item? = nil

}
```

`@SnapshotIgnore` and `@SnapshotShallow` are marker macros used by `@ModelSnapshot`. They don’t emit code by themselves; they only influence snapshot generation.

A nonoptional to-one relationship such as `var child: Child` becomes a
nonoptional `Child.Snapshot`. Optional relationships remain optional, and
to-many relationships map every model to its snapshot. `@SnapshotShallow`
selects the related model's `ShallowSnapshot` instead.

## Expansion

```swift
@Model
final class Item {
    var title: String = ""

    @SnapshotIgnore
    @Relationship
    var related: Item? = nil

    public protocol SnapshotProtocol: Sendable {
        var persistentModelID: PersistentIdentifier { get }
        var title: String { get }
    }

    public struct Snapshot: SnapshotProtocol, Sendable {
        public let persistentModelID: PersistentIdentifier
        public let title: String
        public init(from model: Item) {
            self.persistentModelID = model.persistentModelID
            self.title = model.title
        }
    }

    public struct ShallowSnapshot: SnapshotProtocol, Sendable {
        public let persistentModelID: PersistentIdentifier
        public let title: String
        public init(from model: Item) {
            self.persistentModelID = model.persistentModelID
            self.title = model.title
        }
    }

    public var snapshot: Snapshot {
        return Snapshot(from: self)
    }
    public var shallowSnapshot: ShallowSnapshot {
        return ShallowSnapshot(from: self)
    }
}
```
