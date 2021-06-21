//
//  File.swift
//  
//
//  Created by Maksym Kulyk on 27.04.2021.
//

import Foundation

public extension Collection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable
    subscript (safe index: Index) -> Element?
    {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension Dictionary where Key: Equatable, Value: Equatable
{
    @inlinable func minus(dict: [Key:Value]) -> [Key:Value]
    {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce([Key:Value]()) { (res, entry) -> [Key:Value] in
            var res = res
            res[entry.0] = entry.1
            return res
        }
    }
}

public extension Array
{
    @inlinable func chunked(into size: Int) -> [[Element]]
    {
        return stride(from: 0, to: count, by: size).map
        {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

public extension Array
{
    @inlinable
    subscript(safe range: Range<Index>) -> ArraySlice<Element>
    {
        let lowerBound = range.lowerBound
        if lowerBound < self.endIndex
        {
            return self[lowerBound..<Swift.min(range.endIndex, self.endIndex)]
        }
        else
        {
            return []
        }
    }
    
    @inlinable
    subscript(safe range: ClosedRange<Index>) -> ArraySlice<Element>
    {
        let lowerBound = range.lowerBound
        if lowerBound < self.endIndex
        {
            return self[lowerBound...Swift.min(range.upperBound, self.endIndex - 1)]
        }
        else
        {
            return []
        }
    }
}

public protocol Stackable
{
    associatedtype Element
    func peek() -> Element?
    mutating func push(_ element: Element)
    @discardableResult mutating func pop() -> Element?
}

public extension Stackable
{
    @inlinable var isEmpty: Bool { peek() == nil }
}

public struct Stack<Element>: Stackable where Element: Equatable
{
    private var storage = [Element]()
    public func peek() -> Element? { storage.last }
    public mutating func push(_ element: Element) { storage.append(element)  }
    public mutating func pop() -> Element? { storage.popLast() }
}

extension Stack: Equatable
{
    public static func == (lhs: Stack<Element>, rhs: Stack<Element>) -> Bool { lhs.storage == rhs.storage }
}

extension Stack: CustomStringConvertible
{
    public var description: String { "\(storage)" }
}

extension Stack: ExpressibleByArrayLiteral
{
    public init(arrayLiteral elements: Self.Element...) { storage = elements }
}
