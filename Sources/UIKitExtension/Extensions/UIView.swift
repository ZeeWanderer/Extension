//
//  UIView.swift
//  
//
//  Created by zee wanderer on 02.08.2024.
//

import UIKit

public extension UIView
{
    @inlinable
    func setCorner(radius: CGFloat)
    {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
    
    @inlinable
    func circleCorner()
    {
        superview?.layoutIfNeeded()
        setCorner(radius: frame.height / 2)
    }
}

public extension UIView
{
    @inlinable
    class func getAllSubviews<T: UIView>(from parenView: UIView) -> [T]
    {
        return parenView.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(from: subView) as [T]
            if let view = subView as? T { result.append(view) }
            return result
        }
    }
    
    @inlinable
    class func getAllSubviews(from parenView: UIView, types: [UIView.Type]) -> [UIView]
    {
        return parenView.subviews.flatMap { subView -> [UIView] in
            var result = getAllSubviews(from: subView) as [UIView]
            for type in types
            {
                if subView.classForCoder == type
                {
                    result.append(subView)
                    return result
                }
            }
            return result
        }
    }
    
    @inlinable func getAllSubviews<T: UIView>() -> [T] { return UIView.getAllSubviews(from: self) as [T] }
    @inlinable func get<T: UIView>(all type: T.Type) -> [T] { return UIView.getAllSubviews(from: self) as [T] }
    @inlinable func get(all types: [UIView.Type]) -> [UIView] { return UIView.getAllSubviews(from: self, types: types) }
}
