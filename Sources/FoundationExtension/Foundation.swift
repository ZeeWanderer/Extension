//
//  Foundation.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

import Foundation

// MARK: - Structs -



// MARK: - String
public extension String
{
    @inlinable
    func condenseWhitespace() -> String
    {
        let components = self.components(separatedBy: .whitespaces)
        return components.filter
        { substr in
            !substr.isEmpty
        }.joined(separator: " ")
    }
}

// MARK: - Bool
extension Bool: BinaryRepresentable {}

// MARK: - Int
extension Int: BinaryRepresentable {}

// MARK: - Int8
extension Int8: BinaryRepresentable {}

// MARK: - Int16
extension Int16: BinaryRepresentable {}

// MARK: - Int32
extension Int32: BinaryRepresentable {}

// MARK: - Int64
extension Int64: BinaryRepresentable {}

// MARK: - UInt
extension UInt: BinaryRepresentable {}

// MARK: - UInt8
extension UInt8: BinaryRepresentable {}

// MARK: - UInt16
extension UInt16: BinaryRepresentable {}

// MARK: - UInt32
extension UInt32: BinaryRepresentable {}

// MARK: - UInt64
extension UInt64: BinaryRepresentable {}

// MARK: - Float
extension Float: BinaryRepresentable {}

// MARK: - Double
extension Double: BinaryRepresentable {}

// MARK: - Data
public extension Data
{
    
    // MARK: - BinaryRepresentable load(s)
    @inlinable
    func load<T>(as type: T.Type) -> T where T: BinaryRepresentable
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return bytes.load(as: type)
        }
    }
    
    @inlinable
    func load<T>() -> T where T: BinaryRepresentable
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return bytes.load(as: T.self)
        }
    }
    
    // MARK: - BinaryRepresentableCollection load(s)
    @inlinable
    func load<T>(as type: T.Type) -> T where T: BinaryRepresentableCollection
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return T(bytes.bindMemory(to: type.Element.self))
        }
    }
    
    @inlinable
    func load<T>() -> T where T: BinaryRepresentableCollection
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return T(bytes.bindMemory(to: T.Element.self))
        }
    }
}

// MARK: - UserDefaults
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
