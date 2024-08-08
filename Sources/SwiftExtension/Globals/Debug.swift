//
//  Debug.swift
//  
//
//  Created by Maksym Kulyk on 05.04.2022.
//

/// Helper function that executes given closure only if DEBUG is true
@inlinable
public func debug_action(_ closure: () -> Void)
{
#if DEBUG
    closure()
#endif
}

/// Helper function that prints only if DEBUG is true
@inlinable
public func debug_print(_ items: Any..., separator: String = " ", terminator: String = "\n")
{
    debug_action { print(items, separator: separator, terminator: terminator) }
}

/// Helper function that prints only if DEBUG is true, spawns a task for MainActor
@inlinable
public func debug_print_async(_ items: any Sendable..., separator: String = " ", terminator: String = "\n")
{
    Task { @MainActor in
        debug_action { print(items, separator: separator, terminator: terminator) }
    }
}
