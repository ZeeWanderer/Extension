//
//  Set+BinaryRepresentableCollection.swift
//  
//
//  Created by Maksym Kulyk on 20.05.2024.
//

import Foundation

extension Set: BinaryRepresentableCollection where Element: Hashable, Element: BinaryRepresentable {}
