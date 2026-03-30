//
//  MainActor.swift
//  Extension
//
//  Created by zeewanderer on 28.01.2026.
//

import Foundation

internal final class MainActorResultBox<T: Sendable>: @unchecked Sendable
{
    private let lock = NSLock()
    private var value: T?

    func store(_ value: T)
    {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    func load() -> T?
    {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

public extension MainActor
{
    /// Executes `operation` on the main actor, blocking the current thread if needed.
    /// - Warning: This can deadlock if called off-main while holding locks or resources the main actor needs.
    ///   Use only when a synchronous API is required and you can guarantee no lock/dispatch dependency
    ///   on the main actor. Prefer async APIs when possible.
    static func enforceIsolated<T>(_ operation: @escaping @MainActor () -> T,
                                   file: StaticString = #fileID,
                                   line: UInt = #line) -> T where T: Sendable
    {
        if Thread.isMainThread {
            return MainActor.assumeIsolated(operation)
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            let result = MainActorResultBox<T>()
            Task { @MainActor in
                defer { semaphore.signal() }
                result.store(operation())
            }
            semaphore.wait()
            return result.load()!
        }
    }
}
