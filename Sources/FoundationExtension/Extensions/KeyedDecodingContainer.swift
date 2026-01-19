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
    func decode<K0, V, R>(_ type: [K0:V].Type, forKey key: Key) throws -> [K0:V]
    where K0: RawRepresentable, K0: Decodable, K0.RawValue == R,
          V: Decodable,
          R: Decodable, R: Hashable
    {
        let rawDictionary = try self.decode([R: V].self, forKey: key)
        var dictionary = [K0: V]()
        
        for (key, value) in rawDictionary
        {
            guard let enumKey = K0(rawValue: key) else
            {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath,
                                                                        debugDescription: "Could not parse json key \(key) to a \(K0.self) enum"))
            }
            
            dictionary[enumKey] = value
        }
        
        return dictionary
    }
    
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
        let d = try superDecoder(forKey: key)
        return try .init(from: d)
    }
}
