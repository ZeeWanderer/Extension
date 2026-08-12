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
        guard
            bounds.lowerBound >= 0,
            bounds.upperBound >= bounds.lowerBound,
            bounds.upperBound <= count
        else { return "" }
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start..<end]
    }
    
    @inlinable
    subscript (bounds: CountableClosedRange<Int>) -> Substring
    {
        guard
            bounds.lowerBound >= 0,
            bounds.upperBound >= bounds.lowerBound,
            bounds.upperBound < count
        else { return "" }
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start...end]
    }
    
    @inlinable
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring
    {
        guard bounds.lowerBound >= 0, bounds.lowerBound <= count else { return "" }
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        return self[start..<endIndex]
    }
    
    @inlinable
    subscript (bounds: PartialRangeThrough<Int>) -> Substring
    {
        guard bounds.upperBound >= 0, bounds.upperBound < count else { return "" }
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex...end]
    }
    
    @inlinable
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring
    {
        guard bounds.upperBound >= 0, bounds.upperBound <= count else { return "" }
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex..<end]
    }
    
    @inlinable
    func indent(by spaces: Int) -> String {
        let pad = String(repeating: " ", count: spaces)
        return self.split(separator: "\n").map { pad + $0 }.joined(separator: "\n")
    }
}
