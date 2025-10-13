//
//  ObservableCore.swift
//  Extension
//
//  Created by zeewanderer on 16.07.2025.
//


import Observation
import Foundation
import FoundationExtension

public protocol ObservableCore: Observable, AnyObject
{
    nonisolated
    func withMutation<_M, _MR>(
        keyPath: KeyPath<Self, _M>,
        _ mutation: () throws -> _MR
    ) rethrows -> _MR
    
    nonisolated
    func access<_M>(keyPath: KeyPath<Self, _M>)
}
