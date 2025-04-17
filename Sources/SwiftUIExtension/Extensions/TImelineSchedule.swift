//
//  TImelineSchedule.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI

public extension TimelineSchedule
{
    @inlinable
    static func cyclic(timeOffsets: [TimeInterval]) -> CyclicTimelineSchedule where Self == CyclicTimelineSchedule {
        .init(timeOffsets: timeOffsets)
    }
    
    @inlinable
    static func explicit<S>(timeOffsets: [TimeInterval], referenceDate: Date = .now) -> ExplicitTimelineSchedule<[Date]> where Self == ExplicitTimelineSchedule<S>, S : Sequence, S.Element == Date
    {
        let now = referenceDate
        return .init(timeOffsets.map({ offset in
            now.addingTimeInterval(offset)
        }))
    }
}
