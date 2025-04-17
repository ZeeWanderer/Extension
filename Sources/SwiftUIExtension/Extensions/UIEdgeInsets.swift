//
//  UIEdgeInsets.swift
//  Extension
//
//  Created by zeewanderer on 18.04.2025.
//

import SwiftUI

#if canImport(UIKit)
public extension UIEdgeInsets
{
    @inlinable
    var swiftUIInsets: EdgeInsets
    {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
#endif
