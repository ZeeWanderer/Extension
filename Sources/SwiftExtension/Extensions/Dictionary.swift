//
//  Dictionary.swift
//  
//
//  Created by zeewanderer on 20.05.2024.
//

public extension Dictionary where Value: Equatable
{
    @inlinable
    func minus(dict: [Key:Value]) -> [Key:Value]
    {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce(into: [:]) { (res, entry) in
            let (key, val) = entry
            res[key] = val
        }
    }
}
