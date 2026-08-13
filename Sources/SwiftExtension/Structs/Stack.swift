//
//  Stack.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

public struct Stack<Element>: StackProtocol where Element: Equatable
{
    @usableFromInline internal var p_storage = [Element]()
    @inlinable public func peek() -> Element? { p_storage.last }
    @inlinable public mutating func push(_ element: Element) { p_storage.append(element)  }
    @discardableResult
    @inlinable public mutating func pop() -> Element? { p_storage.popLast() }
}

extension Stack: Equatable
{
    @inlinable
    public static func == (lhs: Stack<Element>, rhs: Stack<Element>) -> Bool { lhs.p_storage == rhs.p_storage }
}

extension Stack: CustomStringConvertible
{
    @inlinable
    public var description: String { "\(p_storage)" }
}

extension Stack: ExpressibleByArrayLiteral
{
    @inlinable
    public init(arrayLiteral elements: Self.Element...) { p_storage = elements }
}
