//
//  JSONDecoder+RawRepresentable.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

@usableFromInline
internal func p_firstJSONToken(in data: Data) -> UInt8?
{
    for byte in data
    {
        switch byte
        {
        case 0x09, 0x0A, 0x0D, 0x20:
            continue
        default:
            return byte
        }
    }

    return nil
}

@usableFromInline
internal struct P_DictionaryDecodingBox<Key, Value>: Decodable
where Key: Decodable, Key: Hashable,
      Value: Decodable
{
    @usableFromInline
    let value: [Key: Value]

    @usableFromInline
    init(from decoder: Decoder) throws
    {
        value = try [Key: Value](from: decoder)
    }
}

@usableFromInline
internal func p_dictionary<Key, Value, RawValue>(
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
        switch p_firstJSONToken(in: data)
        {
        case 0x7B:
            let rawDictionary = try decode([R: V].self, from: data)
            return try p_dictionary(converting: rawDictionary, codingPath: [])
        case 0x5B:
            return try decode(P_DictionaryDecodingBox<K, V>.self, from: data).value
        default:
            break
        }

        do
        {
            let rawDictionary = try decode([R: V].self, from: data)
            return try p_dictionary(converting: rawDictionary, codingPath: [])
        }
        catch let DecodingError.typeMismatch(_, context) where context.codingPath.isEmpty
        {
            return try decode(P_DictionaryDecodingBox<K, V>.self, from: data).value
        }
    }
}
