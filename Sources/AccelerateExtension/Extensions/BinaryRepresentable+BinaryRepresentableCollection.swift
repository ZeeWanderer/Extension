//
//  BinaryRepresentable+BinaryRepresentableCollection.swift
//  Extension
//
//  Created by zeewanderer on 25.03.2025.
//

import Foundation
import FoundationExtension
import Accelerate

public extension BinaryRepresentable where Self: BinaryRepresentableCollection
{
    @inlinable
    init(data: Data)
    {
        self = data.load(as: Self.self)
    }
    
    @inlinable
    var data: Data
    {
        return self.withUnsafeBufferPointer { buffer in
            return Data(buffer: buffer)
        }
    }
}
