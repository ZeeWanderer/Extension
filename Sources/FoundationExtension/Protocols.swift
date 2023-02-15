//
//  Protocols.swift
//  
//
//  Created by Maksym Kulyk on 30.05.2022.
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

// MARK: - BinaryRepresentable

/// Streamlines transformation to and from Data for conforming Collections.
public protocol BinaryRepresentableCollection: Collection where Element: BinaryRepresentable
{
    init(_ buffer: UnsafeBufferPointer<Element>)
    
    /// Generates Data representation
    var data: Data { get }
}

public extension BinaryRepresentableCollection
{
    @inlinable
    var data: Data
    {
        var mutableArray = Array(self)
        return .init(bytes: &mutableArray, count: mutableArray.count * MemoryLayout<Element>.stride)
    }
}
