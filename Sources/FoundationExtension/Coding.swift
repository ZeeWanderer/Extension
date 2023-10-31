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
}

//MARK: SingleValueDecodingContainer
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

//MARK: JSONDecoder
public extension JSONDecoder
{
    @usableFromInline
    internal enum JSONDecoder_dict_decoding: CodingKey
    {
        case self_
    }
    
    @inlinable
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

//MARK: load_collection - json
/// Loads json file from bundle and decodes it into collection
/// - Parameters:
///   - collection: inout collection to decode into
///   - filename: name of the json file
@inlinable
public func load_collection<K, V, R>(_ collection: inout [K:V], _ filename: String)
where K: RawRepresentable, K: Decodable, K.RawValue == R,
      V: Decodable,
      R: Decodable, R: Hashable
{
    let decoder = JSONDecoder()
    if let path = Bundle.main.path(forResource: filename, ofType: "json")
    {
        do
        {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            collection = try decoder.decode([K:V].self, from: data as Data)
        }
        catch
        {
            print(error)
        }
    }
}

// TODO: investigate why this does not work with JSONDecoder::decode specialization for dicts
/// Loads json file from bundle and decodes it into collection
/// - Parameters:
///   - collection: inout collection to decode into
///   - filename: name of the json file
@inlinable
public func load_collection<T: Decodable>(_ collection: inout T, _ filename: String)
{
    let decoder = JSONDecoder()
    if let path = Bundle.main.path(forResource: filename, ofType: "json")
    {
        do
        {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            collection = try decoder.decode(T.self, from: data as Data)
        }
        catch
        {
            print(error)
        }
    }
}
