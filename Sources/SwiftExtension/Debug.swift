//
//  Debug.swift
//  
//
//  Created by Maksym Kulyk on 05.04.2022.
//

@inlinable
public func debug_action(_ closure: () -> Void)
{
#if DEBUG
    closure()
#endif
}

@inlinable
public func debug_print(_ items: Any..., separator: String = " ", terminator: String = "\n")
{
    debug_action { print(items, separator: separator, terminator: terminator) }
}
