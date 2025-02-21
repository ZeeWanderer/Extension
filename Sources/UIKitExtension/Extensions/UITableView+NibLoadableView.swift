//
//  File.swift
//  
//
//  Created by zee wanderer on 02.08.2024.
//

#if canImport(UIKit)
import UIKit

public extension UITableView
{
    
    /**
     Registers ReusableView, NibLoadableView compliant UITableViewCell class
     
     ```
     // register reusable cell
     collectionView.register(CellClass.self)
     ```
     */
    @inlinable
    func register<T: UITableViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView
    {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    /**
     Registers ReusableView, NibLoadableView compliant UITableViewCell class
     
     ```
     // register reusable view
     collectionView.register(ViewClass.self)
     ```
     */
    @inlinable
    func register<T: UITableViewHeaderFooterView>(_: T.Type, ofKind elementKind: String = T.defaultReuseIdentifier) where T: ReusableView, T: NibLoadableView
    {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forHeaderFooterViewReuseIdentifier: T.defaultReuseIdentifier)
    }
}
#endif
