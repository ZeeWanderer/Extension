//
//  P_CacheRangeGate.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// A fair reader-writer gate whose conflicts are limited to overlapping ranges.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_CacheRangeGate: @unchecked Sendable
{
    @usableFromInline
    internal enum Access: Equatable, Sendable
    {
        case metadataRead
        case read(Range<Int>)
        case write(Range<Int>)
        case wholeWrite

        @inlinable
        internal var range: Range<Int>?
        {
            switch self
            {
            case let .read(range), let .write(range):
                range
            case .metadataRead, .wholeWrite:
                nil
            }
        }

        @inlinable
        internal var isRead: Bool
        {
            if case .read = self { return true }
            if case .metadataRead = self { return true }
            return false
        }
    }

    @usableFromInline
    internal struct Lease: Sendable
    {
        @usableFromInline internal let id: UInt64
        @usableFromInline internal let access: Access

        @inlinable
        internal init(id: UInt64, access: Access)
        {
            self.id = id
            self.access = access
        }
    }

    @usableFromInline
    internal struct Waiter
    {
        @usableFromInline internal let lease: Lease
        @usableFromInline internal let resume: @Sendable (Lease) -> Void

        @inlinable
        internal init(
            lease: Lease,
            resume: @escaping @Sendable (Lease) -> Void
        )
        {
            self.lease = lease
            self.resume = resume
        }
    }

    @usableFromInline
    internal final class BlockingWaiter: @unchecked Sendable
    {
        @usableFromInline internal let condition = NSCondition()
        @usableFromInline internal var lease: Lease?

        @inlinable
        internal init() {}

        @inlinable
        internal func wait() -> Lease
        {
            condition.lock()
            while lease == nil
            {
                condition.wait()
            }
            let lease = lease!
            condition.unlock()
            return lease
        }

        @inlinable
        internal func resume(with lease: Lease)
        {
            condition.lock()
            self.lease = lease
            condition.signal()
            condition.unlock()
        }
    }

    @usableFromInline internal let lock = NSLock()
    @usableFromInline internal var nextLeaseID: UInt64 = 0
    @usableFromInline internal var activeLeases: [Lease] = []
    @usableFromInline internal var waiters: [Waiter] = []

    @inlinable
    internal init() {}

    @inlinable
    internal func acquire(_ access: Access) -> Lease
    {
        validate(access)
        let waiter = BlockingWaiter()
        if let lease = enqueue(access, resume: { lease in
            waiter.resume(with: lease)
        })
        {
            return lease
        }
        return waiter.wait()
    }

    @inlinable
    internal func acquire(_ access: Access) async -> Lease
    {
        validate(access)
        return await withCheckedContinuation { continuation in
            if let lease = enqueue(access, resume: { lease in
                continuation.resume(returning: lease)
            })
            {
                continuation.resume(returning: lease)
            }
        }
    }

    @inlinable
    internal func release(_ lease: Lease)
    {
        let resumptions: [(Lease, @Sendable (Lease) -> Void)]
        lock.lock()
        guard let index = activeLeases.firstIndex(where: { $0.id == lease.id })
        else
        {
            lock.unlock()
            preconditionFailure("Unbalanced cache range access")
        }
        precondition(
            activeLeases[index].access == lease.access,
            "Mismatched cache range access"
        )
        activeLeases.remove(at: index)
        resumptions = grantWaitersIfPossible()
        lock.unlock()

        for (lease, resume) in resumptions
        {
            resume(lease)
        }
    }

    /// Returns a lease when access was granted synchronously, or `nil` after
    /// enqueuing the supplied resumption.
    @inlinable
    internal func enqueue(
        _ access: Access,
        resume: @escaping @Sendable (Lease) -> Void
    ) -> Lease?
    {
        lock.lock()
        let lease = makeLease(access)
        if canBypassWaiters(access), !conflictsWithActive(access)
        {
            activeLeases.append(lease)
            lock.unlock()
            return lease
        }
        waiters.append(Waiter(lease: lease, resume: resume))
        lock.unlock()
        return nil
    }

    /// Called with `lock` held.
    @inlinable
    internal func makeLease(_ access: Access) -> Lease
    {
        let id = nextLeaseID
        nextLeaseID &+= 1
        return Lease(id: id, access: access)
    }

    /// A new operation can bypass queued work only when it does not conflict
    /// with any earlier waiter. This prevents overlapping writers from starving
    /// while allowing unrelated byte ranges to continue.
    @inlinable
    internal func canBypassWaiters(_ access: Access) -> Bool
    {
        !waiters.contains { Self.conflicts(access, $0.lease.access) }
    }

    /// Called with `lock` held.
    @inlinable
    internal func conflictsWithActive(_ access: Access) -> Bool
    {
        activeLeases.contains { Self.conflicts(access, $0.access) }
    }

    /// Called with `lock` held.
    @inlinable
    internal func grantWaitersIfPossible() -> [
        (Lease, @Sendable (Lease) -> Void)
    ]
    {
        guard !waiters.isEmpty else { return [] }

        var blockedEarlierAccesses: [Access] = []
        var grantedIndices: [Int] = []
        var resumptions: [(Lease, @Sendable (Lease) -> Void)] = []
        for (index, waiter) in waiters.enumerated()
        {
            let access = waiter.lease.access
            let isBlockedByEarlierWaiter = blockedEarlierAccesses.contains {
                Self.conflicts(access, $0)
            }
            if isBlockedByEarlierWaiter || conflictsWithActive(access)
            {
                blockedEarlierAccesses.append(access)
                continue
            }

            activeLeases.append(waiter.lease)
            grantedIndices.append(index)
            resumptions.append((waiter.lease, waiter.resume))
        }

        for index in grantedIndices.reversed()
        {
            waiters.remove(at: index)
        }
        return resumptions
    }

    @inlinable
    internal static func conflicts(_ lhs: Access, _ rhs: Access) -> Bool
    {
        if case .wholeWrite = lhs { return true }
        if case .wholeWrite = rhs { return true }
        if case .metadataRead = lhs { return false }
        if case .metadataRead = rhs { return false }
        if lhs.isRead, rhs.isRead { return false }
        return lhs.range!.overlaps(rhs.range!)
    }

    @inlinable
    internal func validate(_ access: Access)
    {
        guard let range = access.range else { return }
        precondition(
            range.lowerBound >= 0 && !range.isEmpty,
            "Cache range access must be nonempty and nonnegative"
        )
    }

    internal func p_isAcquired(
        overlappingRange range: Range<Int>,
        as expectedAccess: Access
    ) -> Bool
    {
        lock.withLock {
            activeLeases.contains { lease in
                guard lease.access.isRead == expectedAccess.isRead,
                      let activeRange = lease.access.range else {
                    return false
                }
                return activeRange.overlaps(range)
            }
        }
    }

    internal var p_hasActiveWholeWrite: Bool
    {
        lock.withLock {
            activeLeases.contains { $0.access == .wholeWrite }
        }
    }

    internal var p_waiterCount: Int
    {
        lock.withLock { waiters.count }
    }
}
