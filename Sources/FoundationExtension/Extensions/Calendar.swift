//
//  Calendar.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation

public extension Calendar
{
    /// Returns difference in `day` component of dates.
    /// Example: `2021-11-10 15:43:12` and `2021-11-11 11:18:10` returns `1`
    @inlinable
    func dayComponentDifference(_ from: Date, and to: Date) -> Int
    {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        
        return numberOfDays.day!
    }
}
