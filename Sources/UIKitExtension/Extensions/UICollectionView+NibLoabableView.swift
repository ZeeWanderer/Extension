//
//  UICollectionView+NibLoabableView.swift
//
//
//  Created by zee wanderer on 02.08.2024.
//

import UIKit

public extension UICollectionView
{
    /**
     Registers ReusableView, NibLoadableView compliant UICollectionViewCell class
     
     ```
     // register reusable cell
     collectionView.register(CellClass.self)
     ```
     */
    @inlinable
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView
    {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    /**
     Registers ReusableView, NibLoadableView compliant UICollectionReusableView class
     
     ```
     // register reusable view
     collectionView.register(ViewClass.self)
     ```
     */
    @inlinable
    func register<T: UICollectionReusableView>(_: T.Type, ofKind elementKind: String = T.defaultReuseIdentifier) where T: ReusableView, T: NibLoadableView
    {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: T.defaultReuseIdentifier)
    }
}
