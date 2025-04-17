//
//  Result.swift
//  Extension
//
//  Created by zeewanderer on 13.03.2025.
//

public extension Result
{
    @inlinable
    @inline(__always)
    var isFailure: Bool
    {
        switch self
        {
        case .success:
            return false
        case .failure:
            return true
        }
    }
    
    @inlinable
    @inline(__always)
    var isSuccess: Bool
    {
        switch self
        {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
