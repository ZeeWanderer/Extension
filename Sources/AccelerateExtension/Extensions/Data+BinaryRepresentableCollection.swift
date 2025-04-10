//
//  Foundation+BinaryRepresentableCollection.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation
import FoundationExtension
import Accelerate

public extension Data
{
    @inlinable
    func load<T: BinaryRepresentableCollection>(as type: T.Type) -> T
    {
        return self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return T(bytes.bindMemory(to: type.Element.self))
        }
    }
    
    @inlinable
    @inline(__always)
    func load<T: BinaryRepresentableCollection>() -> T
    {
        load(as: T.self)
    }
    
    @inlinable
    func saferLoad<T: BinaryRepresentableCollection>(as type: T.Type) -> T?
    {
        let elementStride = MemoryLayout<T.Element>.stride
        
        guard self.count % elementStride == 0 else
        { return nil }
        
        return self.withUnsafeBytes { rawBuffer -> T? in
            guard let baseAddress = rawBuffer.baseAddress
            else { return nil }
            
            let addressInt = Int(bitPattern: baseAddress)
            if addressInt % MemoryLayout<T.Element>.alignment == 0
            {
                let typedBuffer = rawBuffer.bindMemory(to: T.Element.self)
                return T(typedBuffer)
            }
            else
            {
                return withUnsafeTemporaryAllocation(
                    byteCount: self.count,
                    alignment: MemoryLayout<T.Element>.alignment
                ) { tmpBuffer -> T? in
                    // Copy the bytes from the data into the temporary buffer.
                    memcpy(tmpBuffer.baseAddress, baseAddress, self.count)
                    let typedBuffer = UnsafeRawBufferPointer(start: tmpBuffer.baseAddress, count: self.count)
                        .bindMemory(to: T.Element.self)
                    return T(typedBuffer)
                }
            }
        }
    }
    
    @inlinable
    @inline(__always)
    func saferLoad<T>() -> T? where T: BinaryRepresentableCollection
    {
        saferLoad(as: T.self)
    }
}
