//
//  Foundation+BinaryRepresentableCollection.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

// MARK: - Data
public extension Data
{
    // MARK: - BinaryRepresentableCollection load(s)
    @inlinable
    func load<T>(as type: T.Type) -> T where T: BinaryRepresentableCollection
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return T(bytes.bindMemory(to: type.Element.self))
        }
    }
    
    @inlinable
    func load<T>() -> T where T: BinaryRepresentableCollection
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return T(bytes.bindMemory(to: T.Element.self))
        }
    }
}
