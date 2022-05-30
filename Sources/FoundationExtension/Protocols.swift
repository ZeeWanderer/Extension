//
//  Protocols.swift
//  
//
//  Created by Maksym Kulyk on 30.05.2022.
//

import Foundation

// MARK: - BinaryRepresentable

/// Streamlines transformation to and from Data for conforming types.
public protocol BinaryRepresentable
{
    /// Generates Data representation
    var data: Data { get }
}

// MARK: - BinaryRepresentable

/// Streamlines transformation to and from Data for conforming Collections.
public protocol BinaryRepresentableCollection: Collection where Element: BinaryRepresentable
{
    init(_ buffer: UnsafeBufferPointer<Element>)
    
    /// Generates Data representation
    var data: Data { get }
}
