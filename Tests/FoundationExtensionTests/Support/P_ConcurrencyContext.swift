//
//  P_ConcurrencyContext.swift
//
//
//  Created by zeewanderer on 10.09.2026.
//

import Foundation

enum P_ConcurrencyContext
{
    @TaskLocal static var marker: String?

    struct Snapshot: Sendable
    {
        let operation: String
        let taskID: Int?
        let isMainThread: Bool
        let marker: String?
    }

    final class Recorder: @unchecked Sendable
    {
        let p_lock = NSLock()
        var p_snapshots: [Snapshot] = []

        func record(_ operation: String)
        {
            let snapshot = Snapshot(
                operation: operation,
                taskID: withUnsafeCurrentTask { $0?.hashValue },
                isMainThread: Thread.isMainThread,
                marker: marker
            )
            p_lock.withLock { p_snapshots.append(snapshot) }
        }

        var snapshots: [Snapshot] { p_lock.withLock { p_snapshots } }
    }
}
