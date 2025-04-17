//
//  Optional.swift
//
//
//  Created by zee wanderer on 09.09.2024.
//

public extension Optional
{
    @_transparent
    var isNil: Bool
    {
        guard case Optional.none = self else { return false }
        return true
    }
    
    @_transparent
    var isNotNil: Bool
    {
        !self.isNil
    }
    
    @_transparent
    var isSome: Bool
    {
        guard case Optional.some = self else { return false }
        return true
    }
    
    @_transparent
    func orEmpty() -> String where Wrapped == String
    {
        return self ?? ""
    }
    
    @_transparent
    func orFalse() -> Bool where Wrapped == Bool
    {
        return self ?? false
    }
    
    @_transparent
    func orTrue() -> Bool where Wrapped == Bool
    {
        return self ?? true
    }
    
    @_transparent
    func orEmpty<T>() -> [T] where Wrapped == Array<T>
    {
        return self ?? []
    }
}
