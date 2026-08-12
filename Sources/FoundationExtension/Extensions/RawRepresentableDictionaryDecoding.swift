//
//  RawRepresentableDictionaryDecoding.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

@usableFromInline
internal func dictionary<Key, Value, RawValue>(
    converting rawDictionary: [RawValue: Value],
    codingPath: [CodingKey]
) throws -> [Key: Value]
where Key: RawRepresentable, Key.RawValue == RawValue,
      RawValue: Hashable
{
    var dictionary = [Key: Value]()
    dictionary.reserveCapacity(rawDictionary.count)

    for (rawKey, value) in rawDictionary
    {
        guard let key = Key(rawValue: rawKey) else
        {
            let invalidKey = AnyCodingKey(stringValue: String(describing: rawKey))
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: codingPath + [invalidKey],
                    debugDescription: "Could not decode JSON key \(rawKey) as \(Key.self)"
                )
            )
        }

        dictionary[key] = value
    }

    return dictionary
}

public extension JSONDecoder
{
    /// Decodes a JSON dictionary whose object keys are raw values of `Key`.
    ///
    /// Use this overload for dictionaries keyed by a `RawRepresentable` type,
    /// such as a string-backed enum. Nested dictionaries stored in decoded
    /// model properties use the matching keyed-container overload.
    @inlinable
    func decode<K, V, R>(
        _ type: [K: V].Type,
        from data: Data
    ) throws -> [K: V]
    where K: RawRepresentable, K: Decodable, K.RawValue == R,
          V: Decodable,
          R: Decodable, R: Hashable
    {
        let rawDictionary = try decode([R: V].self, from: data)
        return try dictionary(converting: rawDictionary, codingPath: [])
    }
}

public extension KeyedDecodingContainer
{
    /// Decodes a model property whose JSON object keys are raw values of its
    /// dictionary key type.
    @inlinable
    func decode<K0, V, R>(
        _ type: [K0: V].Type,
        forKey key: Key
    ) throws -> [K0: V]
    where K0: RawRepresentable, K0: Decodable, K0.RawValue == R,
          V: Decodable,
          R: Decodable, R: Hashable
    {
        let rawDictionary = try decode([R: V].self, forKey: key)
        return try dictionary(
            converting: rawDictionary,
            codingPath: codingPath + [key]
        )
    }
}
