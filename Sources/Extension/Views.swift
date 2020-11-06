//
//  Views.swift
//  Extension
//
//  Created by Maksym Kulyk on 9/14/20.
//  Copyright © 2020 max. All rights reserved.
//

import UIKit

// -MARK: UIView EXTENSION

extension UIView
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

// -MARK: ReusableView EXTENSION

protocol ReusableView: class
{
    static var defaultReuseIdentifier: String { get }
}

extension ReusableView where Self: UIView
{
    static var defaultReuseIdentifier: String
    {
        return NSStringFromClass(self)
    }
}

// -MARK: NibLoadableView EXTENSION

protocol NibLoadableView: class
{
    static var nibName: String { get }
}

extension NibLoadableView where Self: UIView
{
    static var nibName: String
    {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
}

// -MARK: UICollectionView EXTENSION
extension UICollectionView
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
    
    func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
}
