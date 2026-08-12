//
//  KeyedDecodingContainer.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public extension KeyedDecodingContainer
{
    @inlinable
    func decode<Element>(_ type: Lossy<[Element]>.Type, forKey key: Key) throws -> Lossy<[Element]> where Element: Codable
    {
        guard contains(key) else { return .init() }
        let d = try superDecoder(forKey: key)
        return try .init(from: d)
    }
    
    @inlinable
    func decode<T>(_ type: Lossy<T?>.Type, forKey key: Key) throws -> Lossy<T?> where T: Codable
    {
        guard contains(key) else { return .init() }
        let d = try superDecoder(forKey: key)
        return try .init(from: d)
    }
    
    @inlinable
    func decode<T>(_ type: Lossy<[T]?>.Type, forKey key: Key) throws -> Lossy<[T]?> where T: Codable
    {
        guard contains(key) else { return .init() }
        let d = try superDecoder(forKey: key)
        return try .init(from: d)
    }
    
    @inlinable
    func decode<T>(_ type: Lossy<T>.Type, forKey key: Key) throws -> Lossy<T> where T: Codable
    {
        do {
            return .init(wrappedValue: try decode(T.self, forKey: key))
        } catch {
            let d = try superDecoder(forKey: key)
            let path = P_LossyInspect.codingPath(error, from: d)
            let raw = P_LossyInspect.rawString(from: d)
            d.lossyReporter.recordLoss(
                raw: raw,
                codingPath: path,
                message: "Failed to decode required value",
                underlying: error
            )
            throw error
        }
    }
}
