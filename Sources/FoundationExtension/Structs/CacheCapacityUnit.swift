//
//  CacheCapacityUnit.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

/// Identifies the unit used by cache capacity telemetry.
///
/// Built-in stores use ``bytes`` or ``entries``. Custom stores can define a
/// domain-specific unit, such as `"database-pages"`, without changing the
/// dispatcher or maintenance report types.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheCapacityUnit:
    RawRepresentable,
    Hashable,
    Sendable,
    ExpressibleByStringLiteral,
    CustomStringConvertible
{
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

    /// Byte capacity as measured and documented by the reporting store.
    public static let bytes = Self(rawValue: "bytes")
    /// Entry-count capacity.
    public static let entries = Self(rawValue: "entries")
}
