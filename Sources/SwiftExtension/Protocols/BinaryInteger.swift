//
//  BinaryInteger.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

public extension BinaryInteger
{
    @inlinable
    @inline(__always) var isEven: Bool { isMultiple(of: 2) }
    
    @inlinable
    @inline(__always) var isOdd:  Bool { !isEven }
}
