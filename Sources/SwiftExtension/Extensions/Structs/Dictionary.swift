//
//  Dictionary.swift
//  Extension
//
//  Created by zeewanderer on 20.05.2024.
//

public extension Dictionary where Value: Equatable
{
    @inlinable
    func minus(dict: [Key:Value]) -> [Key:Value]
    {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce(into: [:]) { (res, entry) in
            let (key, val) = entry
            res[key] = val
        }
    }
    
    @inlinable
    @inline(__always)
    subscript (_ keys: Key...) -> [Key: Value]
    {
        get {
            keys.reduce(into: [:]) { partialResult, key in
                partialResult[key] = self[key]
            }
        }
        
        set {
            for key in keys {
                self[key] = newValue[key]
            }
        }
    }
    
    @inlinable
    @inline(__always)
    subscript (_ keys: Key..., default defaultValue: Value) -> [Key: Value]
    {
        get {
            keys.reduce(into: [:]) { partialResult, key in
                partialResult[key] = self[key] ?? defaultValue
            }
        }
        
        set {
            for key in keys {
                self[key] = newValue[key] ?? defaultValue
            }
        }
    }
    
    @inlinable
    @inline(__always)
    subscript (_ keys: Key..., default defaultValue: [Key: Value]) -> [Key: Value]
    {
        get {
            keys.reduce(into: [:]) { partialResult, key in
                partialResult[key] = self[key] ?? defaultValue[key]
            }
        }
        
        set {
            for key in keys {
                self[key] = newValue[key] ?? defaultValue[key]
            }
        }
    }
}
