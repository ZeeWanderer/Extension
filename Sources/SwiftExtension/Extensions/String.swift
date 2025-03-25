//
//  String.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

public extension String
{
    @inlinable
    subscript (i: Int) -> Character
    {
        return self[index(startIndex, offsetBy: i)]
    }
    
    @inlinable
    subscript (bounds: CountableRange<Int>) -> Substring
    {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < start { return "" }
        return self[start..<end]
    }
    
    @inlinable
    subscript (bounds: CountableClosedRange<Int>) -> Substring
    {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < start { return "" }
        return self[start...end]
    }
    
    @inlinable
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring
    {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        if end < start { return "" }
        return self[start...end]
    }
    
    @inlinable
    subscript (bounds: PartialRangeThrough<Int>) -> Substring
    {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < startIndex { return "" }
        return self[startIndex...end]
    }
    
    @inlinable
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring
    {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < startIndex { return "" }
        return self[startIndex..<end]
    }
}
