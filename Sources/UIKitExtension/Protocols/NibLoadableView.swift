//
//  NibLoadableView.swift
//
//
//  Created by zee wanderer on 02.08.2024.
//

#if canImport(UIKit)
import UIKit

public protocol NibLoadableView: AnyObject
{
    static var nibName: String { get }
}

public extension NibLoadableView where Self: UIView
{
    @inlinable
    static var nibName: String
    {
        return String(describing: Self.self)
    }
}
#endif
