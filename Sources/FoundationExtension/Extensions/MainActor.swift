//
//  MainActor.swift
//  Extension
//
//  Created by zeewanderer on 28.01.2026.
//

import Foundation

public extension MainActor
{
    /// Executes `operation` on the main actor, blocking the current thread if needed.
    /// - Note: Safe on the main thread; avoid calling while holding locks needed by the main actor.
    static func enforceIsolated<T>(_ operation: @escaping @MainActor () -> T,
                                   file: StaticString = #fileID,
                                   line: UInt = #line) -> T where T: Sendable
    {
        if Thread.isMainThread {
            return MainActor.assumeIsolated(operation)
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            var result: T?
            Task { @MainActor in
                defer { semaphore.signal() }
                result = operation()
            }
            semaphore.wait()
            return result!
        }
    }
}
