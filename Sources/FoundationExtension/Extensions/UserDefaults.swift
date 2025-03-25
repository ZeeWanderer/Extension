//
//  UserDefaults.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation

public extension UserDefaults
{
    @inlinable
    func set(_ value: Any?, forKey defaultName: some RawRepresentable<String>)
    {
        self.set(value, forKey: defaultName.rawValue)
    }
    
    @inlinable
    func set(_ value: Int, forKey defaultName: some RawRepresentable<String>)
    {
        self.set(value, forKey: defaultName.rawValue)
    }

    @inlinable
    func set(_ value: Float, forKey defaultName: some RawRepresentable<String>)
    {
        self.set(value, forKey: defaultName.rawValue)
    }

    @inlinable
    func set(_ value: Double, forKey defaultName: some RawRepresentable<String>)
    {
        self.set(value, forKey: defaultName.rawValue)
    }

    @inlinable
    func set(_ value: Bool, forKey defaultName: some RawRepresentable<String>)
    {
        self.set(value, forKey: defaultName.rawValue)
    }
    
    @inlinable
    func set(_ url: URL?, forKey defaultName: some RawRepresentable<String>)
    {
        self.set(url, forKey: defaultName.rawValue)
    }
    
    @inlinable
    func object(forKey defaultName: some RawRepresentable<String>) -> Any?
    {
        self.object(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func string(forKey defaultName: some RawRepresentable<String>) -> String?
    {
        return self.string(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func bool(forKey defaultName: some RawRepresentable<String>) -> Bool
    {
        return self.bool(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func data(forKey defaultName: some RawRepresentable<String>) -> Data?
    {
        return self.data(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func url(forKey defaultName: some RawRepresentable<String>) -> URL?
    {
        return self.url(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func float(forKey defaultName: some RawRepresentable<String>) -> Float?
    {
        return self.float(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func double(forKey defaultName: some RawRepresentable<String>) -> Double?
    {
        return self.double(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func integer(forKey defaultName: some RawRepresentable<String>) -> Int?
    {
        return self.integer(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func array(forKey defaultName: some RawRepresentable<String>) -> [Any]?
    {
        return self.array(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func stringArray(forKey defaultName: some RawRepresentable<String>) -> [String]?
    {
        return self.stringArray(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func dictionary(forKey defaultName: some RawRepresentable<String>) -> [String: Any]?
    {
        return self.dictionary(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func dictionaryWithValues(forKeys defaultNames: [some RawRepresentable<String>]) -> [String: Any]
    {
        let keys = defaultNames.map(\.rawValue)
        return self.dictionaryWithValues(forKeys: keys)
    }
    
    @inlinable
    func removeObject(forKey defaultName: some RawRepresentable<String>)
    {
        self.removeObject(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func register(defaults: [some RawRepresentable<String>: Any])
    {
        let defaults = Dictionary(uniqueKeysWithValues: defaults.map { (key, value) in
            (key.rawValue, value)
        })
        self.register(defaults: defaults)
    }
}
