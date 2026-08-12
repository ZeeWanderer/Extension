//
//  RouterDestinationContext.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Context supplied while constructing a routed destination.
public struct RouterDestinationContext
{
    /// Resolved path identifier, type-erased for destination-independent use.
    public var pathID: AnyHashable?

    /// Optional identifier for the object that requested navigation.
    public var requester: AnyHashable?

    /// Application-defined values used by custom destination factories.
    public var userInfo: [AnyHashable: Any]

    public init(
        pathID: AnyHashable? = nil,
        requester: AnyHashable? = nil,
        userInfo: [AnyHashable: Any] = [:]
    )
    {
        self.pathID = pathID
        self.requester = requester
        self.userInfo = userInfo
    }

    public subscript(key: AnyHashable) -> Any?
    {
        get { userInfo[key] }
        set { userInfo[key] = newValue }
    }

    /// Returns the path identifier when it has the requested concrete type.
    public func pathID<ID>(as type: ID.Type = ID.self) -> ID?
    where ID: Hashable
    {
        pathID?.base as? ID
    }

    /// Returns the requester when it has the requested concrete type.
    public func requester<ID>(as type: ID.Type = ID.self) -> ID?
    where ID: Hashable
    {
        requester?.base as? ID
    }

    /// Returns a context value when it has the requested type.
    public func value<Value>(
        for key: AnyHashable,
        as type: Value.Type = Value.self
    ) -> Value?
    {
        userInfo[key] as? Value
    }
}
