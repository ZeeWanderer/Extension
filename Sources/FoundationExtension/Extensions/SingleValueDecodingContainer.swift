//
//  SingleValueDecodingContainer.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public extension SingleValueDecodingContainer
{
    @inlinable
    func decode<K, V, R>(_ type: [K:V].Type) throws -> [K:V]
    where K: RawRepresentable, K: Decodable, K.RawValue == R,
          V: Decodable,
          R: Decodable, R: Hashable
    {
        let rawDictionary = try self.decode([R: V].self)
        var dictionary = [K: V]()
        
        for (key, value) in rawDictionary
        {
            guard let enumKey = K(rawValue: key) else
            {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath,
                                                                        debugDescription: "Could not parse json key \(key) to a \(K.self) enum"))
            }
            
            dictionary[enumKey] = value
        }
        
        return dictionary
    }
}
