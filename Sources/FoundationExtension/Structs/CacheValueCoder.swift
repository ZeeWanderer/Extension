//
//  CacheValueCoder.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

/// Encodes and decodes values stored by a disk cache store.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheValueCoder<Value: Sendable>: Sendable
{
    @usableFromInline
    internal let p_encode: @Sendable (Value) throws -> Data
    @usableFromInline
    internal let p_decode: @Sendable (Data) throws -> Value

    @inlinable
    public init(
        encode: @escaping @Sendable (Value) throws -> Data,
        decode: @escaping @Sendable (Data) throws -> Value
    )
    {
        self.p_encode = encode
        self.p_decode = decode
    }

    @inlinable
    public func encode(_ value: Value) throws -> Data
    {
        try p_encode(value)
    }

    @inlinable
    public func decode(_ data: Data) throws -> Value
    {
        try p_decode(data)
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheValueCoder where Value == Data
{
    static let data = Self(encode: { $0 }, decode: { $0 })
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheValueCoder where Value: Codable
{
    @inlinable
    static var json: Self
    {
        Self(
            encode: { value in
                try JSONEncoder().encode(value)
            },
            decode: { data in
                try JSONDecoder().decode(Value.self, from: data)
            }
        )
    }
}
