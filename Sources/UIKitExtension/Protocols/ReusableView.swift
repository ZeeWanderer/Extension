//
//  ReusableView.swift
//
//
//  Created by zee wanderer on 02.08.2024.
//

import UIKit

public protocol ReusableView: AnyObject
{
    static var defaultReuseIdentifier: String { get }
}

public extension ReusableView where Self: UIView
{
    @inlinable
    static var defaultReuseIdentifier: String
    {
        return String(describing: Self.self)
    }
}
