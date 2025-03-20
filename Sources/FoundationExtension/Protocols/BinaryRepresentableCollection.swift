//
//  BinaryRepresentableCollection.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation
import Accelerate

// MARK: - BinaryRepresentableCollection

/// Streamlines transformation to and from Data for conforming Collections.
public protocol BinaryRepresentableCollection: Collection, BinaryRepresentable, AccelerateBuffer
{
    init(_ buffer: UnsafeBufferPointer<Element>)
}
