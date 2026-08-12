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
        self.withUnsafeBytes { bytes in
            bytes.loadUnaligned(as: type)
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
        guard count >= MemoryLayout<T>.size else { return nil }
        return withUnsafeBytes { bytes in
            bytes.loadUnaligned(as: type)
        }
    }
    
    @inlinable
    @inline(__always)
    func saferLoad<T: BinaryRepresentable>() -> T?
    {
        saferLoad(as: T.self)
    }
}
