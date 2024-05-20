//
//  UserDefaults.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

public extension UserDefaults
{
    @inlinable
    func object(forKey defaultName: some RawRepresentable<String>) -> Any?
    {
        self.object(forKey: defaultName.rawValue)
    }
    
    @inlinable
    func set(_ value: Any?, forKey defaultName: some RawRepresentable<String>)
    {
        self.set(value, forKey: defaultName.rawValue)
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
}
