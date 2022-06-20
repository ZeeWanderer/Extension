//
//  Collections.swift
//  
//
//  Created by Maksym Kulyk on 04.05.2022.
//


//MARK: - Collection
public extension Collection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable
    subscript (safe index: Index) -> Element?
    {
        return indices.contains(index) ? self[index] : nil
    }
}

//MARK: - Dictionary
public extension Dictionary where Value: Equatable
{
    @inlinable
    func minus(dict: [Key:Value]) -> [Key:Value]
    {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce(into: [:]) { (res, entry) in
            let (key, val) = entry
            res[key] = val
        }
    }
}

//MARK: - Array
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
        let start = Swift.max(range.lowerBound, 0)
        let end = Swift.min(range.upperBound, endIndex)
        if end <= start  { return [] }
        return self[start..<end]
    }
    
    @inlinable
    subscript(safe range: CountableClosedRange<Index>) -> ArraySlice<Element>
    {
        let start = Swift.max(range.lowerBound, 0)
        let end = Swift.min(range.upperBound, endIndex - 1)
        if end < start { return [] }
        return self[start...end]
    }
}

//MARK: - StackProtocol
public protocol StackProtocol
{
    associatedtype Element
    func peek() -> Element?
    mutating func push(_ element: Element)
    mutating func pop() -> Element?
}

public extension StackProtocol
{
    @inlinable
    var isEmpty: Bool { peek() == nil }
}

public struct Stack<Element>: StackProtocol where Element: Equatable
{
    @usableFromInline internal var storage = [Element]()
    @inlinable public func peek() -> Element? { storage.last }
    @inlinable public mutating func push(_ element: Element) { storage.append(element)  }
    @discardableResult
    @inlinable public mutating func pop() -> Element? { storage.popLast() }
}

extension Stack: Equatable
{
    @inlinable
    public static func == (lhs: Stack<Element>, rhs: Stack<Element>) -> Bool { lhs.storage == rhs.storage }
}

extension Stack: CustomStringConvertible
{
    @inlinable
    public var description: String { "\(storage)" }
}

extension Stack: ExpressibleByArrayLiteral
{
    @inlinable
    public init(arrayLiteral elements: Self.Element...) { storage = elements }
}
