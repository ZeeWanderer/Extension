//
//  ObjectCache.swift
//  Extension
//
//  Created by zeewanderer on 19.04.2025.
//

import Foundation

/// A simple wrapper over NSCache, to be used when both key Key and Value are objects
public final class ObjectCache<Key: AnyObject, Value: AnyObject>
{
    @usableFromInline
    internal let cache = NSCache<Key, Value>()
    
    @inlinable
    public init(configure: (NSCache<Key, Value>) -> Void = { cache in })
    { configure(cache) }
    
    @inlinable
    public func insert(_ value: Value, forKey key: Key)
    { cache.setObject(value, forKey: key) }
    
    @inlinable
    public func value(forKey key: Key) -> Value?
    { cache.object(forKey: key) }
    
    @inlinable
    public func removeValue(forKey key: Key)
    { cache.removeObject(forKey: key) }
    
    @inlinable
    public subscript(key: Key) -> Value?
    {
        get { value(forKey: key) }
        set {
            if let v = newValue { insert(v, forKey: key) }
            else { removeValue(forKey: key) }
        }
    }
}
