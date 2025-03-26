//
//  Data+BinaryRepresentable.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation

public extension Data
{
    @inlinable
    func load<T: BinaryRepresentable>(as type: T.Type) -> T
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return bytes.load(as: type)
        }
    }
    
    @inlinable
    @inline(__always)
    func load<T: BinaryRepresentable>() -> T
    {
        load(as: T.self)
    }
    
    @inlinable
    func saferLoad<T: BinaryRepresentable>(as type: T.Type) -> T?
    {
        guard self.count >= MemoryLayout<T>.size
        else { return nil }
        
        return self.withUnsafeBytes { rawBuffer -> T? in
            guard let baseAddress = rawBuffer.baseAddress
            else { return nil }
            
            if Int(bitPattern: baseAddress) % MemoryLayout<T>.alignment == 0
            {
                return baseAddress.load(as: T.self)
            }
            else
            {
                let value = UnsafeMutablePointer<T>.allocate(capacity: 1)
                defer { value.deallocate() }
                memcpy(value, baseAddress, MemoryLayout<T>.size)
                return value.pointee
            }
        }
    }
    
    @inlinable
    @inline(__always)
    func saferLoad<T: BinaryRepresentable>() -> T?
    {
        saferLoad(as: T.self)
    }
}
