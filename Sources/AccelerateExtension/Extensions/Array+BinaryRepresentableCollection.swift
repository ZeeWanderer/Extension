//
//  Array+BinaryRepresentableCollection.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation
import FoundationExtension
import Accelerate

extension Array: BinaryRepresentable where Element: BinaryRepresentable {}
extension Array: BinaryRepresentableCollection where Element: BinaryRepresentable {}
