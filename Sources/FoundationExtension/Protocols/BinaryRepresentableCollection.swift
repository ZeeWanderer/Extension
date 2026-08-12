//
//  BinaryRepresentableCollection.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation

// MARK: - BinaryRepresentableCollection

/// A collection whose fixed-width element representations are stored contiguously.
public protocol BinaryRepresentableCollection: Collection, BinaryRepresentable where Element: BinaryRepresentable
{
    init(_ buffer: UnsafeBufferPointer<Element>)
}
