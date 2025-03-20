//
//  Set+BinaryRepresentableCollection.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation
import Accelerate

extension Set: @retroactive AccelerateBuffer {
    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
        try Array(self).withUnsafeBufferPointer(body)
    }
}
extension Set: BinaryRepresentable { }
extension Set: BinaryRepresentableCollection { }
