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
    /// Convenience function to sleep in seconds.
    /// - Note: Function converts `TimeInterval` to nanoseconds so mind the upper `Double` limit of `10^308.3`.
    @inlinable
    static func sleep(seconds duration: TimeInterval) async throws
    {
#if swift(>=5.7)
        if #available(iOS 16, *)
        {
            try await Task.sleep(until: .now + .seconds(duration), clock: .continuous)
        }
        else
        {
            let delay = UInt64(duration * Double(NSEC_PER_SEC))
            try await Task.sleep(nanoseconds: delay)
        }
#else
        let delay = UInt64(duration * Double(NSEC_PER_SEC))
        try await Task.sleep(nanoseconds: delay)
#endif
    }
    
    /// Convenience function to delay execution in seconds. Intended for code clarity.
    /// - Note: Function converts `TimeInterval` to nanoseconds so mind the upper `Double` limit of `10^308.3`.
    @inlinable
    static func delay(by delayInterval: TimeInterval) async throws
    {
        try await Task.sleep(seconds: delayInterval)
    }
}

