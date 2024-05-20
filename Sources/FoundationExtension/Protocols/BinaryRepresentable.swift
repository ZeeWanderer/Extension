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
        var selfMutable = self
        return .init(bytes: &selfMutable, count: MemoryLayout<BinaryRepresentableType>.size)
    }
}
