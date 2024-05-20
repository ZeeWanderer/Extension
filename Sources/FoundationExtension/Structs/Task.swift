//
//  Task.swift
//
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

public extension Task where Success == Never, Failure == Never
{
    /// Convenience function to sleep in seconds.
    /// - Note: On iOS15 and lower function converts `TimeInterval` to nanoseconds so mind the upper `Double` limit of `10^308.3`. On iOS16+ `Instant` API i used.
    @inlinable
    static func sleep(seconds duration: TimeInterval) async throws
    {
        
        if #available(iOS 16, *)
        {
            try await Task.sleep(until: .now + .seconds(duration), clock: .continuous)
        }
        else
        {
            let delay = UInt64(duration * Double(NSEC_PER_SEC))
            try await Task.sleep(nanoseconds: delay)
        }
    }
    
    /// Convenience function to delay execution in seconds. Intended for code clarity.
    /// - Note: Function converts `TimeInterval` to nanoseconds so mind the upper `Double` limit of `10^308.3`.
    @inlinable
    static func delay(by delayInterval: TimeInterval) async throws
    {
        try await Task.sleep(seconds: delayInterval)
    }
}
