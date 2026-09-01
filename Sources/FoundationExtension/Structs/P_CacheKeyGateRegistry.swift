//
//  P_CacheKeyGateRegistry.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_CacheKeyGateRegistry<Key: Hashable>: @unchecked Sendable
{
    @usableFromInline
    internal struct Record
    {
        @usableFromInline internal let gate: P_CacheReadWriteGate
        @usableFromInline internal var users: Int

        @inlinable
        internal init(gate: P_CacheReadWriteGate, users: Int)
        {
            self.gate = gate
            self.users = users
        }
    }

    @usableFromInline internal let lock = NSLock()
    @usableFromInline internal let maximumRetainedGateCount: Int
    @usableFromInline internal var records: [Key: Record] = [:]

    @inlinable
    internal init(maximumRetainedGateCount: Int = 1024)
    {
        self.maximumRetainedGateCount = max(0, maximumRetainedGateCount)
    }

    @inlinable
    internal func retainGate(for key: Key) -> P_CacheReadWriteGate
    {
        lock.lock()
        defer { lock.unlock() }

        if var record = records[key]
        {
            record.users += 1
            records[key] = record
            return record.gate
        }

        let gate = P_CacheReadWriteGate()
        records[key] = Record(
            gate: gate,
            users: 1
        )
        return gate
    }

    @inlinable
    internal func releaseGate(
        _ gate: P_CacheReadWriteGate,
        for key: Key
    )
    {
        lock.lock()
        defer { lock.unlock() }

        guard var record = records[key] else
        {
            assertionFailure("Missing cache key gate")
            return
        }
        precondition(record.gate === gate, "Mismatched cache key gate")
        record.users -= 1
        if record.users == 0, records.count > maximumRetainedGateCount
        {
            records.removeValue(forKey: key)
        }
        else
        {
            records[key] = record
        }
    }
}
