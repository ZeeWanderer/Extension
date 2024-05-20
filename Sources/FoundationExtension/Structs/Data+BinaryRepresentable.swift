//
//  Data+BinaryRepresentable.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

public extension Data
{
    
    // MARK: - BinaryRepresentable load(s)
    @inlinable
    func load<T>(as type: T.Type) -> T where T: BinaryRepresentable
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return bytes.load(as: type)
        }
    }
    
    @inlinable
    func load<T>() -> T where T: BinaryRepresentable
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return bytes.load(as: T.self)
        }
    }
}
