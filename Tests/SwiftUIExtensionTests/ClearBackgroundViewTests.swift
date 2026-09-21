//
//  ClearBackgroundViewTests.swift
//
//
//  Created by zeewanderer on 10.09.2026.
//

import XCTest
@testable import SwiftUIExtension

#if canImport(UIKit)
import UIKit

@MainActor
final class ClearBackgroundViewTests: XCTestCase
{
    func testClearsBackgroundWhenAttachedToAnExistingHierarchy()
    {
        let container = UIView()
        container.backgroundColor = .red
        let parent = UIView()
        container.addSubview(parent)
        parent.addSubview(ClearBackgroundView.P_View())

        XCTAssertEqual(container.backgroundColor, .clear)
    }

    func testClearsBackgroundWhenTheHierarchyLaterEntersAWindow()
    {
        let parent = UIView()
        parent.addSubview(ClearBackgroundView.P_View())
        let container = UIView()
        container.backgroundColor = .red
        container.addSubview(parent)

        let window = UIWindow()
        window.addSubview(container)

        XCTAssertEqual(container.backgroundColor, .clear)
    }
}
#endif
