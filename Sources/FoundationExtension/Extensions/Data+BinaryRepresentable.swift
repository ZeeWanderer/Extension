//
//  Data+BinaryRepresentable.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation
import Accelerate

public extension Data
{
    
    // MARK: - BinaryRepresentable load(s)
    @inlinable
    func load<T: BinaryRepresentable>(as type: T.Type) -> T
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return bytes.load(as: type)
        }
    }
    
    @inlinable
    func load<T: BinaryRepresentable>() -> T
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return bytes.load(as: T.self)
        }
    }
}
