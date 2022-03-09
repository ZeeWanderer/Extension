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
