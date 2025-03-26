//
//  Set+BinaryRepresentableCollection.swift
//  
//
//  Created by Zee Wanderer on 20.05.2024.
//

import Foundation
import FoundationExtension
import Accelerate

extension Set: @retroactive AccelerateBuffer where Element: BinaryRepresentable
{
    @inlinable
    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R
    {
        let contiguous = ContiguousArray(self)
        return try contiguous.withUnsafeBufferPointer(body)
    }
}
extension Set: BinaryRepresentable where Element: BinaryRepresentable  { }
extension Set: BinaryRepresentableCollection where Element: BinaryRepresentable { }
