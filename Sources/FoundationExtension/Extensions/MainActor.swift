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
