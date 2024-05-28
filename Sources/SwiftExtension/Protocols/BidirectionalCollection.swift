//
//  BidirectionalCollection.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

public extension BidirectionalCollection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable
    @inline(__always)
    subscript (safe index: Self.Index) -> Self.Element?
    {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// Returns the element at the specified index if it is within bounds, otherwise default.
    @inlinable
    @inline(__always)
    subscript (_ index: Self.Index, default defaultValue: Self.Element) -> Self.Element
    {
        return self[safe: index] ?? defaultValue
    }
}
