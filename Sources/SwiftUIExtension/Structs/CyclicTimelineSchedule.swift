//
//  CyclicTimelineSchedule.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI

public struct CyclicTimelineSchedule: TimelineSchedule
{
    public let timeOffsets: [TimeInterval]

    @inlinable
    public init(timeOffsets: [TimeInterval])
    {
        self.timeOffsets = timeOffsets
    }

    @inlinable
    public func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries
    {
        Entries(last: startDate, offsets: timeOffsets)
    }

    public struct Entries: Sequence, IteratorProtocol
    {
        @usableFromInline internal var p_last: Date
        @usableFromInline internal let p_offsets: [TimeInterval]

        @inlinable
        public init(last: Date, offsets: [TimeInterval])
        {
            self.p_last = last
            self.p_offsets = offsets
        }

        @usableFromInline
        internal var p_index: Int = -1

        @inlinable
        mutating public func next() -> Date?
        {
            guard !p_offsets.isEmpty else { return nil }
            p_index = (p_index + 1) % p_offsets.count

            p_last = p_last.addingTimeInterval(p_offsets[p_index])

            return p_last
        }
    }
}
