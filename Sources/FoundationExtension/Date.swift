//
//  Date.swift
//  
//
//  Created by Maksym Kulyk on 19.11.2021.
//

import Foundation

//MARK: - Date
extension Date: RawRepresentable
{
    private static let formatter = ISO8601DateFormatter()
    
    public var rawValue: String
    {
        Date.formatter.string(from: self)
    }
    
    public init?(rawValue: String)
    {
        self = Date.formatter.date(from: rawValue) ?? Date()
    }
}

//MARK: - Calendar
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
