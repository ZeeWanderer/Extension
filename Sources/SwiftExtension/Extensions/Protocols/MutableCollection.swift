//
//  MutableCollection.swift
//  Extension
//
//  Created by zee wanderer on 24.10.2024.
//

public extension MutableCollection where Self: BidirectionalCollection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable
    @inline(__always)
    subscript(safe index: Index) -> Element?
    {
        get {
            return indices.contains(index) ? self[index] : nil
        }
        
        set {
            if let value = newValue, indices.contains(index)
            {
                self[index] = value
            }
        }
    }
}
