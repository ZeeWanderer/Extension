//
//  CacheKeyEncoder.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

/// Converts a cache key into stable bytes used to derive a disk file name.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheKeyEncoder<Key: Sendable>: Sendable
{
    @usableFromInline
    internal let p_encode: @Sendable (Key) throws -> Data

    @inlinable
    public init(_ encode: @escaping @Sendable (Key) throws -> Data)
    {
        self.p_encode = encode
    }

    @inlinable
    public func encode(_ key: Key) throws -> Data
    {
        try p_encode(key)
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheKeyEncoder where Key == String
{
    static let utf8 = Self { Data($0.utf8) }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheKeyEncoder where Key: Encodable
{
    @inlinable
    static var json: Self
    {
        Self { key in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            return try encoder.encode(key)
        }
    }
}
