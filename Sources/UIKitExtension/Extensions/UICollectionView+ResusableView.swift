//
//  UICollectionView+ResusableView.swift
//
//
//  Created by zee wanderer on 02.08.2024.
//

import UIKit

public extension UICollectionView
{
    /**
     Registers ReusableView compliant UICollectionViewCell class
     
     ```
     // register reusable cell
     collectionView.register(CellClass.self)
     ```
     */
    @inlinable
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView
    {
        register(T.self, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    /**
     Registers ReusableView compliant UICollectionReusableView class
     
     ```
     // register reusable view
     collectionView.register(ViewClass.self)
     ```
     */
    @inlinable
    func register<T: UICollectionReusableView>(_: T.Type, ofKind elementKind: String = T.defaultReuseIdentifier) where T: ReusableView
    {
        register(T.self, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    /**
     Dequeues ReusableView compliant Cell.
     
     - Parameter indexPath: The index path specifying the location of the supplementary view in the collection view. The data source receives this information when it is asked for the view and should just pass it along. This method uses the information to perform additional configuration based on the view’s position in the collection view.
     - Returns: A valid UICollectionReusableView object.
     
     - Important: Cell class must be registered first
     ```
     // register reusable view
     collectionView.register(CellClass.self)
     
     // dequeue reusable cell
     let cell: CellClass = collectionView.dequeueReusableCell(forIndexPath: indexPath)
     ```
     */
    @inlinable @available(*, deprecated, renamed: "dequeueReusableCell(for:)")
    func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
    
    /**
     Dequeues ReusableView compliant Cell.
     
     - Parameter indexPath: The index path specifying the location of the supplementary view in the collection view. The data source receives this information when it is asked for the view and should just pass it along. This method uses the information to perform additional configuration based on the view’s position in the collection view.
     - Returns: A valid UICollectionReusableView object.
     
     - Important: Cell class must be registered first
     ```
     // register reusable view
     collectionView.register(CellClass.self)
     
     // dequeue reusable cell
     let cell: CellClass = collectionView.dequeueReusableCell(forIndexPath: indexPath)
     ```
     */
    @inlinable
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
    
    /**
     Dequeues ReusableView compliant Supplementary View.
     
     - Parameter elementKind: The kind of supplementary view to retrieve. This value is defined by the layout object.
     - Parameter indexPath: The index path specifying the location of the supplementary view in the collection view. The data source receives this information when it is asked for the view and should just pass it along. This method uses the information to perform additional configuration based on the view’s position in the collection view.
     - Returns: A valid UICollectionReusableView object.
     
     - Important: View class must be registered first
     ```
     // dequeue supplementary view
     let sup: ViewClass = collectionView.dequeueReusableSupplementaryView(ofKind: kind, for: indexPath)
     ```
     */
    @inlinable
    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind elementKind: String, for indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let sup = dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue SupplementaryView with identifier: \(T.defaultReuseIdentifier)")
        }
        return sup
    }
}
