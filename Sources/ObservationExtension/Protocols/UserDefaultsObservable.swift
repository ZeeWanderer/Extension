//
//  UserDefaultsObservable.swift
//  Extension
//
//  Created by zeewanderer on 20.03.2025.
//

import Observation
import Foundation
import FoundationExtension

/// Helper protocol to make UserDefaults backed properties observable
@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public protocol UserDefaultsObservable: Observable
{
    associatedtype UserDefaultsKey: RawRepresentable<String>
}

// MARK: - Get
@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public extension UserDefaultsObservable
{
    @inlinable
    func userDefaultsGet<Value: RawRepresentable>(_ key: UserDefaultsKey, _ userDefaults: UserDefaults = .standard) -> Value?
    {
        guard let stored = userDefaults.object(forKey: key)
        else { return nil }
        
        if let value = stored as? Value
        { return value }
        
        if let data = stored as? Data,
           let binaryType = Value.self as? BinaryRepresentable.Type,
           let value = binaryType.init(validating: data) as? Value
        {
            return value
        }
        
        guard let rawValue = stored as? Value.RawValue
        else { return nil }
        let value = Value(rawValue: rawValue)
        return value
    }
    
    @inlinable
    func userDefaultsGet<Value>(_ key: UserDefaultsKey, _ userDefaults: UserDefaults = .standard) -> Value?
    {
        guard let stored = userDefaults.object(forKey: key)
        else { return nil }
        
        if let value = stored as? Value
        { return value }
        
        if let data = stored as? Data,
           let binaryType = Value.self as? BinaryRepresentable.Type,
           let value = binaryType.init(validating: data) as? Value
        {
            return value
        }
        
        return nil
    }
}

// MARK: - Set
@available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
public extension UserDefaultsObservable
{
    /// Sets given value in UserDefaults.
    /// - Returns: `true` if operation succeeds
    /// ## Overview
    /// If the value is property list compliant then it's stored as is.
    /// If the value conforms to BinaryRepresentable then binary data is stored.
    /// If the value conforms to RawRepresentable it's RawValue is stored as is and if it can't be stored directly then `rawValue` is passed to ``userDefaultsSet(_:_:newValue:)`` as `newValue`.
    /// - Important: In case the serialization fails calls fatalError as that indicates programmer error
    @inlinable
    @discardableResult
    func userDefaultsSet<Value>(_ key: UserDefaultsKey, _ userDefaults: UserDefaults = .standard, newValue: Value?) -> Bool
    {
        guard let newValue else
        {
            userDefaults.set(newValue, forKey: key)
            return true
        }
        
        if PropertyListSerialization.propertyList(newValue, isValidFor: .xml)
        {
            userDefaults.set(newValue, forKey: key)
            return true
        }
        
        if let binaryValue = newValue as? BinaryRepresentable
        {
            userDefaults.set(binaryValue.data, forKey: key)
            return true
        }
        
        if let rawRepresentableValue = newValue as? any RawRepresentable
        {
            let rawValue = rawRepresentableValue.rawValue
            return userDefaultsSet(key, userDefaults, newValue: rawValue)
        }
        
        fatalError("UserDefaultsObservable::userDefaultsSet - unable to serialize value to PropertyList: \(String(describing: newValue))")
    }
}
