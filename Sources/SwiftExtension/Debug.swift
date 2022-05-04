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
