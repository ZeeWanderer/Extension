//
//  Coding.swift
//  
//
//  Created by Maksym Kulyk on 19.11.2021.
//

import Foundation

//MARK: - DECODING



//MARK: KeyedDecodingContainer
public extension KeyedDecodingContainer
{
    func decode<K, V, R>(_ type: [K:V].Type, forKey key: Key) throws -> [K:V]
    where K: RawRepresentable, K: Decodable, K.RawValue == R,
          V: Decodable,
          R: Decodable, R: Hashable
    {
        let rawDictionary = try self.decode([R: V].self, forKey: key)
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

//MARK: SingleValueDecodingContainer
public extension SingleValueDecodingContainer
{
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


//MARK: JSONDecoder
public extension JSONDecoder
{
    private enum JSONDecoder_dict_decoding: CodingKey
    {
        case self_
    }
    
    func decode<K, V, R>(_ type: [K:V].Type, from data: Data) throws -> [K:V]
    where K: RawRepresentable, K: Decodable, K.RawValue == R,
          V: Decodable,
          R: Decodable, R: Hashable
    {
        let rawDictionary = try self.decode([R: V].self, from: data)
        var dictionary = [K: V]()
        
        for (key, value) in rawDictionary
        {
            guard let enumKey = K(rawValue: key) else
            {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [JSONDecoder_dict_decoding.self_],
                                                                        debugDescription: "Could not parse json key \(key) to a \(K.self) enum"))
            }
            
            dictionary[enumKey] = value
        }
        
        return dictionary
    }
}
