//
//  BinaryRepresentableCollection.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

// MARK: - BinaryRepresentableCollection

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
