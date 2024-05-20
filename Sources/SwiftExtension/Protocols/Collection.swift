//
//  Collection.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

public extension Collection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable
    subscript (safe index: Self.Index) -> Self.Element?
    {
        return indices.contains(index) ? self[index] : nil
    }
}
