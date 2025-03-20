//
//  BinaryRepresentable.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation
import Accelerate

// MARK: - BinaryRepresentable

/// Streamlines transformation to and from Data for conforming types.
public protocol BinaryRepresentable
{   
    init?(data: Data)
    
    /// Generates Data representation
    var data: Data { get }
}

public extension BinaryRepresentable
{
    @inlinable
    init?(data: Data)
    {
        self = data.load(as: Self.self)
    }
    
    @inlinable
    var data: Data
    {
        return withUnsafePointer(to: self) { pointer in
            return Data(bytes: pointer, count: MemoryLayout<Self>.size)
        }
    }
}

public extension BinaryRepresentable where Self: BinaryRepresentableCollection
{
    @inlinable
    init?(data: Data)
    {
        self = data.load(as: Self.self)
    }
    
    @inlinable
    var data: Data
    {
        return self.withUnsafeBufferPointer { buffer in
            return Data(buffer: buffer)
        }
    }
}
