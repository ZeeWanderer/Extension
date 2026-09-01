//
//  P_CacheReadWriteGate.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_CacheReadWriteGate: @unchecked Sendable
{
    @usableFromInline
    internal enum Access: Equatable
    {
        case read
        case write
    }

    @usableFromInline
    internal struct Waiter
    {
        @usableFromInline internal let access: Access
        @usableFromInline internal let resume: @Sendable () -> Void

        @inlinable
        internal init(
            access: Access,
            resume: @escaping @Sendable () -> Void
        )
        {
            self.access = access
            self.resume = resume
        }
    }

    @usableFromInline
    internal final class BlockingWaiter: @unchecked Sendable
    {
        @usableFromInline internal let condition = NSCondition()
        @usableFromInline internal var isReady = false

        @inlinable
        internal init() {}

        @inlinable
        internal func wait()
        {
            condition.lock()
            while !isReady
            {
                condition.wait()
            }
            condition.unlock()
        }

        @inlinable
        internal func resume()
        {
            condition.lock()
            isReady = true
            condition.signal()
            condition.unlock()
        }
    }

    @usableFromInline internal let lock = NSLock()
    @usableFromInline internal var activeReaders = 0
    @usableFromInline internal var writerIsActive = false
    @usableFromInline internal var waiters: [Waiter] = []

    @inlinable
    internal init() {}

    @inlinable
    internal func acquire(_ access: Access)
    {
        guard !tryAcquire(access) else { return }
        let waiter = BlockingWaiter()
        enqueue(access) {
            waiter.resume()
        }
        waiter.wait()
    }

    @inlinable
    internal func acquire(_ access: Access) async
    {
        guard !tryAcquire(access) else { return }
        await withCheckedContinuation { continuation in
            enqueue(access) {
                continuation.resume()
            }
        }
    }

    @inlinable
    internal func tryAcquire(_ access: Access) -> Bool
    {
        lock.lock()
        defer { lock.unlock() }
        guard waiters.isEmpty, canAcquireImmediately(access) else
        {
            return false
        }
        markAcquired(access)
        return true
    }

    @inlinable
    internal func release(_ access: Access)
    {
        let resumptions: [@Sendable () -> Void]
        lock.lock()
        switch access
        {
        case .read:
            precondition(activeReaders > 0, "Unbalanced cache read access")
            activeReaders -= 1
        case .write:
            precondition(writerIsActive, "Unbalanced cache write access")
            writerIsActive = false
        }
        resumptions = grantWaitersIfPossible()
        lock.unlock()

        for resume in resumptions
        {
            resume()
        }
    }

    @inlinable
    internal func enqueue(
        _ access: Access,
        resume: @escaping @Sendable () -> Void
    )
    {
        var resumeImmediately = false
        lock.lock()
        if waiters.isEmpty, canAcquireImmediately(access)
        {
            markAcquired(access)
            resumeImmediately = true
        }
        else
        {
            waiters.append(Waiter(access: access, resume: resume))
        }
        lock.unlock()

        if resumeImmediately
        {
            resume()
        }
    }

    @inlinable
    internal func canAcquireImmediately(_ access: Access) -> Bool
    {
        switch access
        {
        case .read:
            !writerIsActive
        case .write:
            !writerIsActive && activeReaders == 0
        }
    }

    @inlinable
    internal func markAcquired(_ access: Access)
    {
        switch access
        {
        case .read:
            activeReaders += 1
        case .write:
            writerIsActive = true
        }
    }

    /// Called with `lock` held.
    @inlinable
    internal func grantWaitersIfPossible() -> [@Sendable () -> Void]
    {
        guard !writerIsActive, let first = waiters.first else { return [] }

        switch first.access
        {
        case .write:
            guard activeReaders == 0 else { return [] }
            writerIsActive = true
            waiters.removeFirst()
            return [first.resume]
        case .read:
            var count = 0
            while count < waiters.count, waiters[count].access == .read
            {
                count += 1
            }
            let readers = waiters.prefix(count)
            waiters.removeFirst(count)
            activeReaders += count
            return readers.map(\.resume)
        }
    }
}
