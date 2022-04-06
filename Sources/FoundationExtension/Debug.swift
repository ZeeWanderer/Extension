//
//  Debug.swift
//  
//
//  Created by Maksym Kulyk on 05.04.2022.
//

import Foundation

@available(*, deprecated, renamed: "debug_action(_:)")
@inlinable
public func debugAction(_ closure: () -> Void)
{
#if DEBUG
    closure()
#endif
}

@inlinable
public func debug_action(_ closure: () -> Void)
{
#if DEBUG
    closure()
#endif
}

@available(*, deprecated, renamed: "debug_print(_:separator:terminator:)")
@inlinable
public func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n")
{
    debug_action { print(items, separator: separator, terminator: terminator) }
}

@inlinable
public func debug_print(_ items: Any..., separator: String = " ", terminator: String = "\n")
{
    debug_action { print(items, separator: separator, terminator: terminator) }
}
