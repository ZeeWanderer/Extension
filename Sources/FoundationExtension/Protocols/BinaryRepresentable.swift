//
//  BinaryRepresentable.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation

// MARK: - BinaryRepresentable

/// Streamlines transformation to and from Data for conforming types.
/// - Warning: Ensure that the conforming Type is BitwiseCopyable
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
