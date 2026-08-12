//
//  CGFloat+BinaryRepresentable.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation
import CoreGraphics
import SwiftExtension
import FoundationExtension

extension CGFloat: BinaryRepresentable
{
    public init(data: Data)
    {
        self.init(CGFloat.NativeType(data: data))
    }

    public init?(validating data: Data)
    {
        guard let value = CGFloat.NativeType(validating: data) else { return nil }
        self.init(value)
    }

    public var data: Data { native.data }
}
