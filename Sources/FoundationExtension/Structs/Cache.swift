//
//  Cache.swift
//  Extension
//
//  Created by zeewanderer on 19.04.2025.
//

import Foundation

/// A simple swifty wrapper over NSCache that supports any Hashable as key an has no constraints on value
/// - Important: Uses ``WrappedKey`` and ``Entry`` to wrap passed values. If both are objects consider using ``ObjectCache``
public final class Cache<Key: Hashable, Value>
{
    public final class WrappedKey: NSObject
    {
        public let key: Key
        
        @inlinable
        @inline(__always)
        public init(_ key: Key) { self.key = key }
        
        @inlinable
        @inline(__always)
        public override var hash: Int { return key.hashValue }
        
        @inlinable
        public override func isEqual(_ object: Any?) -> Bool
        {
            guard let value = object as? WrappedKey else
            { return false }
            
            return value.key == key
        }
    }
    
    public final class Entry
    {
        public let value: Value
        
        @inlinable
        @inline(__always)
        init(value: Value) { self.value = value }
    }
    
    @usableFromInline
    internal let cache: NSCache<WrappedKey, Entry> = .init()
    
    @inlinable
    public init(configure: (NSCache<WrappedKey, Entry>) -> Void = { cache in })
    { configure(cache) }
    
    @inlinable
    public func insert(_ value: Value, forKey key: Key)
    { cache.setObject(Entry(value: value), forKey: WrappedKey(key)) }
    
    @inlinable
    public func value(forKey key: Key) -> Value?
    { cache.object(forKey: WrappedKey(key))?.value }
    
    @inlinable
    public func removeValue(forKey key: Key)
    { cache.removeObject(forKey: WrappedKey(key)) }
    
    @inlinable
    public subscript(key: Key) -> Value?
    {
        get { return value(forKey: key) }
        set {
            if let v = newValue { insert(v, forKey: key) }
            else { removeValue(forKey: key) }
        }
    }
}
