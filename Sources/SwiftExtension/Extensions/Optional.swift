//
//  Optional.swift
//
//
//  Created by zee wanderer on 09.09.2024.
//

public extension Optional
{
    @inlinable
    @inline(__always)
    var isNil: Bool
    {
        guard case Optional.none = self else { return false }
        return true
    }
    
    @inlinable
    @inline(__always)
    var isNotNil: Bool
    {
        !self.isNil
    }
    
    @inlinable
    @inline(__always)
    var isSome: Bool
    {
        guard case Optional.some = self else { return false }
        return true
    }
}
