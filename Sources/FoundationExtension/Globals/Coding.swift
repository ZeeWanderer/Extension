//
//  Coding.swift
//  
//
//  Created by zeewanderer on 19.11.2021.
//

import Foundation
import SwiftExtension


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

@inlinable
public func load_collection<K, V, R>(_ type: [K:V].Type, _ filename: String) -> [K:V]?
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
            return try decoder.decode([K:V].self, from: data)
        }
        catch
        {
            debug_print(error)
            return nil
        }
    }
    return nil
}

@inlinable
public func load_collection<K: Decodable>(_ type: K.Type, _ filename: String) -> K?
where K: Decodable
{
    let decoder = JSONDecoder()
    if let path = Bundle.main.path(forResource: filename, ofType: "json")
    {
        do
        {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            return try decoder.decode(K.self, from: data)
        }
        catch
        {
            debug_print(error)
            return nil
        }
    }
    return nil
}

@inlinable
public func load_object<K: Decodable>(_ filename: String) -> K?
where K: Decodable
{
    let decoder = JSONDecoder()
    if let path = Bundle.main.path(forResource: filename, ofType: "json")
    {
        do
        {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            return try decoder.decode(K.self, from: data)
        }
        catch
        {
            debug_print(error)
            return nil
        }
    }
    return nil
}
