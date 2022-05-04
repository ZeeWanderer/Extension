//
//  Concurrency.swift
//  
//
//  Created by Maksym Kulyk on 04.05.2022.
//

import Foundation

// MARK: - Task
public extension Task where Success == Never, Failure == Never
{
    /// Convenience function to delay execution in seconds.
    /// - Note: Function converts `TimeInterval` to nanoseconds so mind the upper `Double` limit of `10^308.3`.
    @inlinable
    static func delay(by delayInterval: TimeInterval) async throws
    {
        let delay = UInt64(delayInterval * Double(NSEC_PER_SEC))
        try await Task.sleep(nanoseconds: delay)
    }
}

