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
    /// If the caller is already on the main thread, this runs immediately via `MainActor.assumeIsolated`.
    /// Otherwise, this synchronously hops to `DispatchQueue.main`, which is the executor used by `MainActor`.
    /// - Warning: This can deadlock if the calling thread is holding locks, queues, or other resources that
    ///   code on the main actor needs before `operation` can start or complete. Use only when a synchronous
    ///   API is required. Prefer async APIs when possible.
    static func enforceIsolated<T>(_ operation: @escaping @MainActor () -> T,
                                   file: StaticString = #fileID,
                                   line: UInt = #line) -> T where T: Sendable
    {
        if Thread.isMainThread {
            return MainActor.assumeIsolated(operation, file: file, line: line)
        }

        return DispatchQueue.main.sync {
            MainActor.assumeIsolated(operation, file: file, line: line)
        }
    }
}
