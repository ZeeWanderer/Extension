//
//  KeychainObservable.swift
//  Extension
//
//  Created by zeewanderer on 20.03.2025.
//

import Observation
import Foundation
import FoundationExtension
#if canImport(KeychainSwift)
import KeychainSwift

/// Helper protocol to make KeychainSwift backed properties observable
public protocol KeychainObservable
{
    associatedtype KeychainKey: RawRepresentable<String>
}

public extension KeychainObservable
{
    @inlinable
    func keychainGet<Value: Decodable>(_ key: KeychainKey, _ keychain: KeychainSwift = .init()) -> Value?
    {
        guard let data = keychain.getData(key.rawValue),
              let value = try? JSONDecoder().decode(Value.self, from: data)
        else { return nil }
        return value
    }
    
    @inlinable
    func keychainGet<Value: Decodable>(_ key: KeychainKey, _ keychain: KeychainSwift = .init(), defaultValue: Value) -> Value
    {
        guard let data = keychain.getData(key.rawValue),
              let value = try? JSONDecoder().decode(Value.self, from: data)
        else { return defaultValue }
        return value
    }
    
    @inlinable
    func keychainSet<Value: Encodable>(_ key: KeychainKey, _ keychain: KeychainSwift = .init(), newValue: Value?)
    {
        if let newValue = newValue, let data = try? JSONEncoder().encode(newValue)
        { keychain.set(data, forKey: key.rawValue) }
        else { keychain.delete(key.rawValue) }
    }
    
    @inlinable
    func keychainSet<Value: Encodable>(_ key: KeychainKey, _ keychain: KeychainSwift = .init(), defaultValue: Value, newValue: Value?)
    {
        let newValue = newValue ?? defaultValue
        if let data = try? JSONEncoder().encode(newValue)
        { keychain.set(data, forKey: key.rawValue) }
        else { keychain.delete(key.rawValue) }
    }
}
#endif
