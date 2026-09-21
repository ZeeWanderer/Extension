//
//  KeyedDecodingContainer+RawRepresentable.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

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
        do
        {
            let rawDictionary = try decode([R: V].self, forKey: key)
            return try p_dictionary(
                converting: rawDictionary,
                codingPath: codingPath + [key]
            )
        }
        catch let DecodingError.typeMismatch(_, context)
            where context.codingPath.count == codingPath.count + 1 &&
            context.codingPath.last?.stringValue == key.stringValue
        {
            return try decode(P_DictionaryDecodingBox<K0, V>.self, forKey: key).value
        }
    }
}
