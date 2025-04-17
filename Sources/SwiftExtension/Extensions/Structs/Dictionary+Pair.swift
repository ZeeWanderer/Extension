//
//  Dictionary+Pair.swift
//  Extension
//
//  Created by zeewanderer on 17.04.2025.
//

public extension Dictionary
{
    @inlinable
    @inline(__always)
    subscript<T: Hashable, U: Hashable>(_ first: T, _ second: U) -> Value? where Key == Pair<T, U>
    {
        get {
            return self[Pair(first, second)]
        }
        set {
            self[Pair(first, second)] = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    subscript<T: Hashable, U: Hashable>(_ first: T, _ second: U, default defaultValue: @autoclosure () -> Value) -> Value where Key == Pair<T, U>
    {
        get {
            return self[Pair(first, second)] ?? defaultValue()
        }
        set {
            self[Pair(first, second)] = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    subscript<T: Hashable, U: Hashable>(_ first: T) -> [Value] where Key == Pair<T, U>
    {
        get {
            self.compactMap { (key, value) in
                key.first == first ? value : nil
            }
        }
    }
}
