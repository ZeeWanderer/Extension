//
//  DictionaryBuilder.swift
//  Extension
//
//  Created by zeewanderer on 13.03.2025.
//

@resultBuilder
public struct DictionaryBuilder<Key: Hashable, Value>
{
    public static func buildBlock(_ components: [Key: Value]...) -> [Key: Value]
    {
        components.reduce(into: [:]) { result, component in
            result.merge(component) { (_, new) in new }
        }
    }
    
    public static func buildOptional(_ component: [Key: Value]?) -> [Key: Value]
    {
        component ?? [:]
    }
    
    public static func buildEither(first component: [Key: Value]) -> [Key: Value]
    {
        component
    }
    
    public static func buildEither(second component: [Key: Value]) -> [Key: Value]
    {
        component
    }
    
    public static func buildArray(_ components: [[Key: Value]]) -> [Key: Value]
    {
        components.reduce(into: [:]) { result, component in
            result.merge(component) { (_, new) in new }
        }
    }
}

public func makeDictionary<Key: Hashable, Value>(@DictionaryBuilder<Key, Value> _ content: () -> [Key: Value]) -> [Key: Value]
{
    content()
}
