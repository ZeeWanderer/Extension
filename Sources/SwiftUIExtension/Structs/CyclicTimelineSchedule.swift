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
        @usableFromInline var last: Date
        @usableFromInline let offsets: [TimeInterval]
        
        @inlinable
        public init(last: Date, offsets: [TimeInterval])
        {
            self.last = last
            self.offsets = offsets
        }
        
        @usableFromInline
        var idx: Int = -1
        
        @inlinable
        mutating public func next() -> Date?
        {
            idx = (idx + 1) % offsets.count
            
            last = last.addingTimeInterval(offsets[idx])
            
            return last
        }
    }
}
