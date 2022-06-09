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
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter
        {
            !$0.isEmpty
        }.joined(separator: " ")
    }
}

// MARK: - Bool
extension Bool: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - Int
extension Int: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - Int8
extension Int8: BinaryRepresentable
{
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - Int16
extension Int16: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - Int32
extension Int32: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - Int64
extension Int64: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - UInt
extension UInt: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - UInt8
extension UInt8: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - UInt16
extension UInt16: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - UInt32
extension UInt32: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - UInt64
extension UInt64: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - Float
extension Float: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

// MARK: - Double
extension Double: BinaryRepresentable
{
    @inlinable
    public var data: Data
    {
        var selfMutable = self
        return Data(bytes: &selfMutable, count: MemoryLayout<Self>.stride)
    }
}

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
