//
//  StackProtocol.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

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
