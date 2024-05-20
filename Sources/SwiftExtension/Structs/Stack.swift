//
//  Stack.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

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
