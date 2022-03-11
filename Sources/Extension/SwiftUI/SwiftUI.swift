//
//  SwiftUI.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

import SwiftUI

public extension UIEdgeInsets
{
    @inlinable
    var swiftUIInsets: EdgeInsets
    {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

public extension EdgeInsets
{
    /// Returns default padding if inset is not 0
    @inlinable
    var trailingDefaultPadding: CGFloat?
    {
        trailing != 0 ? nil : 0
    }
    
    /// Returns default padding if inset is not 0
    @inlinable
    var leadingDefaultPadding: CGFloat?
    {
        leading != 0 ? nil : 0
    }
    
    /// Returns default padding if inset is not 0
    @inlinable
    var topDefaultPadding: CGFloat?
    {
        top != 0 ? nil : 0
    }
    
    /// Returns default padding if inset is not 0
    @inlinable
    var bottomDefaultPadding: CGFloat?
    {
        bottom != 0 ? nil : 0
    }
}
