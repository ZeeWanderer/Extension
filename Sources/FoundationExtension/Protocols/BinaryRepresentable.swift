//
//  BinaryRepresentable.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

// MARK: - BinaryRepresentable

/// Streamlines transformation to and from Data for conforming types.
public protocol BinaryRepresentable
{
    associatedtype BinaryRepresentableType = Self
    
    /// Generates Data representation
    var data: Data { get }
}

public extension BinaryRepresentable
{
    @inlinable
    var data: Data
    {
        return withUnsafePointer(to: self) { pointer in
            return Data(bytes: pointer, count: MemoryLayout<BinaryRepresentableType>.size)
        }
    }
}
