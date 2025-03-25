//
//  Array.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

public extension Array
{
    @inlinable
    func chunked(into size: Int) -> [[Element]]
    {
        return stride(from: 0, to: count, by: size).map
        {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    @inlinable
    subscript(safe range: CountableRange<Index>) -> ArraySlice<Element>
    {
        let start = Swift.max(range.lowerBound, startIndex)
        let end = Swift.min(range.upperBound, endIndex)
        if end <= start  { return [] }
        return self[start..<end]
    }
    
    @inlinable
    subscript(safe range: CountableClosedRange<Index>) -> ArraySlice<Element>
    {
        let start = Swift.max(range.lowerBound, startIndex)
        let end = Swift.min(range.upperBound, endIndex - 1)
        if end < start { return [] }
        return self[start...end]
    }
}
