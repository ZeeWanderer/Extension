//
//  UITableView+ResusableView.swift
//
//
//  Created by zee wanderer on 02.08.2024.
//

#if canImport(UIKit)
import UIKit

public extension UITableView
{
    /**
     Registers ReusableView compliant UITableViewCell class
     
     ```
     // register reusable cell
     collectionView.register(CellClass.self)
     ```
     */
    @inlinable
    func register<T: UITableViewCell>(_: T.Type) where T: ReusableView
    {
        register(T.self, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    /**
     Registers ReusableView compliant UITableViewHeaderFooterView class
     
     ```
     // register reusable view
     collectionView.register(ViewClass.self)
     ```
     */
    @inlinable
    func register<T: UITableViewHeaderFooterView>(_: T.Type, ofKind elementKind: String = T.defaultReuseIdentifier) where T: ReusableView
    {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.defaultReuseIdentifier)
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
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let cell = dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
    
    /**
     Dequeues ReusableView compliant Cell.
     
     - Parameter indexPath: The index path specifying the location of the supplementary view in the collection view. The data source receives this information when it is asked for the view and should just pass it along. This method uses the information to perform additional configuration based on the view’s position in the collection view.
     - Returns: A valid UITableViewCell object.
     
     - Important: Cell class must be registered first
     ```
     // register reusable view
     collectionView.register(CellClass.self)
     
     // dequeue reusable cell
     let cell: CellClass = collectionView.dequeueReusableCell(forIndexPath: indexPath)
     ```
     */
    @inlinable
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T where T: ReusableView
    {
        guard let cell = dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else
        {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
    
    /**
     Dequeues ReusableView compliant Supplementary View.
     
     - Returns: A valid UITableViewHeaderFooterView object.
     - Important: View class must be registered first
     ```
     // dequeue supplementary view
     let sup: ViewClass = collectionView.dequeueReusableSupplementaryView(ofKind: kind, for: indexPath)
     ```
     */
    @inlinable
    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T where T: ReusableView
    {
        guard let sup = dequeueReusableHeaderFooterView(withIdentifier: T.defaultReuseIdentifier) as? T else
        {
            fatalError("Could not dequeue SupplementaryView with identifier: \(T.defaultReuseIdentifier)")
        }
        return sup
    }
}
#endif
