//
//  Views.swift
//  Extension
//
//  Created by Maksym Kulyk on 9/14/20.
//  Copyright © 2020 max. All rights reserved.
//

import UIKit

// -MARK: UIView EXTENSION

public extension UIView
{
    func setCorner(radius: CGFloat)
    {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
    
    func circleCorner()
    {
        superview?.layoutIfNeeded()
        setCorner(radius: frame.height / 2)
    }
}

public extension UIView
{
    
    class func getAllSubviews<T: UIView>(from parenView: UIView) -> [T]
    {
        return parenView.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(from: subView) as [T]
            if let view = subView as? T { result.append(view) }
            return result
        }
    }
    
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
    
    func getAllSubviews<T: UIView>() -> [T] { return UIView.getAllSubviews(from: self) as [T] }
    func get<T: UIView>(all type: T.Type) -> [T] { return UIView.getAllSubviews(from: self) as [T] }
    func get(all types: [UIView.Type]) -> [UIView] { return UIView.getAllSubviews(from: self, types: types) }
}

// -MARK: ReusableView EXTENSION

public protocol ReusableView: AnyObject
{
    static var defaultReuseIdentifier: String { get }
}

public extension ReusableView where Self: UIView
{
    static var defaultReuseIdentifier: String
    {
        return String(describing: Self.self)
    }
}

// -MARK: NibLoadableView EXTENSION

public protocol NibLoadableView: AnyObject
{
    static var nibName: String { get }
}

public extension NibLoadableView where Self: UIView
{
    static var nibName: String
    {
        return String(describing: Self.self)
    }
}

// -MARK: UICollectionView EXTENSION
public extension UICollectionView
{
    
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView
    {
        register(T.self, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView
    {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func register<T: UICollectionReusableView>(_: T.Type, ofKind elementKind: String = T.defaultReuseIdentifier) where T: ReusableView
    {
        register(T.self, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func register<T: UICollectionReusableView>(_: T.Type, ofKind elementKind: String = T.defaultReuseIdentifier) where T: ReusableView, T: NibLoadableView
    {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
    
    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind elementKind: String, for indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let sup = dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue SupplementaryView with identifier: \(T.defaultReuseIdentifier)")
        }
        return sup
    }
}
