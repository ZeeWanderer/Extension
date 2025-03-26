//
//  Float16+BinaryRepresentable.swift
//  Extension
//
//  Created by zeewanderer on 25.03.2025.
//

import Foundation

#if swift(>=5.4) && !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Float16: BinaryRepresentable {}
#endif
