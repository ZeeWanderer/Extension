//
//  Swift.swift
//
//
//  Created by Maksym Kulyk on 31.10.2023.
//

public extension BinaryInteger 
{
    @inlinable
    @inline(__always) var isEven: Bool { isMultiple(of: 2) }
    
    @inlinable
    @inline(__always) var isOdd:  Bool { !isEven }
}
