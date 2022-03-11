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
    @inlinable
    var paddingTrailing: CGFloat?
    {
        trailing != 0 ? trailing : nil
    }
    
    @inlinable
    var paddingLeading: CGFloat?
    {
        leading != 0 ? leading : nil
    }
    
    @inlinable
    var paddingTop: CGFloat?
    {
        top != 0 ? top : nil
    }
    
    @inlinable
    var paddingBottom: CGFloat?
    {
        bottom != 0 ? bottom : nil
    }
}
