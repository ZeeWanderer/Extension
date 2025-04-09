//
//  DictionaryBuilder.swift
//  Extension
//
//  Created by zeewanderer on 13.03.2025.
//

@resultBuilder
public struct DictionaryBuilder<Key: Hashable, Value>
{
    @inlinable
    public static func buildBlock(_ components: [Key: Value]...) -> [Key: Value]
    {
        components.reduce(into: [:]) { result, component in
            result.merge(component) { (_, new) in new }
        }
    }
    
    @inlinable
    public static func buildOptional(_ component: [Key: Value]?) -> [Key: Value]
    {
        component ?? [:]
    }
    
    @inlinable
    public static func buildEither(first component: [Key: Value]) -> [Key: Value]
    {
        component
    }
    
    @inlinable
    public static func buildEither(second component: [Key: Value]) -> [Key: Value]
    {
        component
    }
    
    @inlinable
    public static func buildArray(_ components: [[Key: Value]]) -> [Key: Value]
    {
        components.reduce(into: [:]) { result, component in
            result.merge(component) { (_, new) in new }
        }
    }
}

@inlinable
public func makeDictionary<Key: Hashable, Value>(@DictionaryBuilder<Key, Value> _ content: () -> [Key: Value]) -> [Key: Value]
{
    content()
}
