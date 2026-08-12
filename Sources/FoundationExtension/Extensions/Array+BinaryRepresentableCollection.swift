//
//  Array+BinaryRepresentableCollection.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation

extension Array: BinaryRepresentable where Element: BinaryRepresentable {}
extension Array: BinaryRepresentableCollection where Element: BinaryRepresentable {}
