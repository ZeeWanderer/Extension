//
//  CacheStoreID.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// A stable identifier for one store managed by a ``Cache``.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheStoreID:
    RawRepresentable,
    Hashable,
    Sendable,
    ExpressibleByStringLiteral,
    CustomStringConvertible
{
    /// The identifier used inside a cache configuration.
    public let rawValue: String

    @inlinable
    public init(rawValue: String)
    {
        self.rawValue = rawValue
    }

    @inlinable
    public init(stringLiteral value: String)
    {
        self.init(rawValue: value)
    }

    @inlinable
    public var description: String { rawValue }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheStoreID
{
    /// The conventional identifier for a single memory store.
    static let memory: Self = "memory"
    /// The conventional identifier for a single disk store.
    static let disk: Self = "disk"
}
