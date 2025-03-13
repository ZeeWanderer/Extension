//
//  DictionaryBuilder.swift
//  Extension
//
//  Created by zeewanderer on 13.03.2025.
//

@resultBuilder
struct DictionaryBuilder<Key: Hashable, Value>
{
    static func buildBlock(_ components: [Key: Value]...) -> [Key: Value]
    {
        components.reduce(into: [:]) { result, component in
            result.merge(component) { (_, new) in new }
        }
    }
    
    static func buildOptional(_ component: [Key: Value]?) -> [Key: Value]
    {
        component ?? [:]
    }
    
    static func buildEither(first component: [Key: Value]) -> [Key: Value]
    {
        component
    }
    
    static func buildEither(second component: [Key: Value]) -> [Key: Value]
    {
        component
    }
    
    static func buildArray(_ components: [[Key: Value]]) -> [Key: Value]
    {
        components.reduce(into: [:]) { result, component in
            result.merge(component) { (_, new) in new }
        }
    }
}

func makeDictionary<Key: Hashable, Value>(@DictionaryBuilder<Key, Value> _ content: () -> [Key: Value]) -> [Key: Value]
{
    content()
}
