//
//  P_CacheStoreOwnership.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_CacheStoreOwnership: @unchecked Sendable
{
    @usableFromInline internal let lock = NSLock()
    @usableFromInline internal var owner: UUID?

    @inlinable
    internal init() {}

    @inlinable
    internal func claim(_ owner: UUID) -> Bool
    {
        lock.lock()
        defer { lock.unlock() }
        guard self.owner == nil else { return false }
        self.owner = owner
        return true
    }

    @inlinable
    internal func release(_ owner: UUID)
    {
        lock.lock()
        defer { lock.unlock() }
        guard self.owner == owner else { return }
        self.owner = nil
    }
}
