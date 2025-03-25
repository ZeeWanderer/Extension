//
//  BinaryRepresentableCollection.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation
import FoundationExtension
import Accelerate

// MARK: - BinaryRepresentableCollection

/// Streamlines transformation to and from Data for conforming Collections.
/// - Warning: Ensure that Element is BitwiseCopyable
public protocol BinaryRepresentableCollection: Collection, BinaryRepresentable, AccelerateBuffer where Element: BinaryRepresentable
{
    init(_ buffer: UnsafeBufferPointer<Element>)
}
