//
//  P_CacheIOExecutor.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Dispatch

/// Runs blocking file-system work on a dedicated task executor.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_CacheIOExecutor: Sendable
{
    @usableFromInline internal let taskExecutor: DispatchQueue

    @inlinable
    internal init(label: String)
    {
        taskExecutor = DispatchQueue(
            label: label,
            qos: .utility,
            attributes: .concurrent
        )
    }

    @inlinable
    internal func run<Value: Sendable>(
        _ operation: @escaping @Sendable () throws -> Value
    ) async throws -> Value
    {
        try await withTaskExecutorPreference(
            taskExecutor,
            isolation: nil
        ) {
            try Task.checkCancellation()
            return try operation()
        }
    }
}
