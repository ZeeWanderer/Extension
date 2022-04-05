//
//  Debug.swift
//  
//
//  Created by Maksym Kulyk on 05.04.2022.
//

import Foundation

@inlinable
public func debugAction(_ closure: () -> Void)
{
#if DEBUG
    closure()
#endif
}

@inlinable
public func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n")
{
    debugAction { print(items, separator: separator, terminator: terminator) }
}
