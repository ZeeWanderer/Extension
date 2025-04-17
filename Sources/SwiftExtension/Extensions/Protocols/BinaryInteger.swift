//
//  BinaryInteger.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

public extension BinaryInteger
{
    @_transparent
    var isEven: Bool { isMultiple(of: 2) }
    
    @_transparent
    var isOdd:  Bool { !isEven }
    
    @_transparent
    var isZero: Bool { self == 0 }
    
    @_transparent
    var isNotZero: Bool { self != 0 }
}
