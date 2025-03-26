//
//  Float80+BinaryRepresentable.swift
//  Extension
//
//  Created by zeewanderer on 26.03.2025.
//

import Foundation

#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
@available(macOS 11.0, *)
extension Float80: BinaryRepresentable {}
#endif
