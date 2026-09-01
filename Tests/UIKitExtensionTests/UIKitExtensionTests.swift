//
//  UIKitExtensionTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import XCTest
import FoundationExtension
import UIKitExtension

#if canImport(UIKit)
final class UIColorPublicAPITests: XCTestCase {
    func testHexInitializersAcceptDocumentedPrefixesAndAlphaForms() {
        let expected = UIColor(hex: 0xFF00FF, alpha: 0)
        let variants = [
            UIColor(hex: "FF00FF00"),
            UIColor(hex: "FF00FF", alpha: 0),
            UIColor(hex: "#FF00FF00"),
            UIColor(hex: "0xFF00FF00"),
            UIColor(hex: "0XFF00FF00"),
            UIColor(hex: "0XFF00FFFF", alpha: 0),
        ]

        for variant in variants {
            XCTAssertEqual(variant, expected)
        }
    }

    @MainActor
    func testTopMostViewControllerReturnsAnOrdinaryLeafController() {
        let controller = UIViewController()

        XCTAssertTrue(controller.topMostViewController() === controller)
    }

    @MainActor
    func testTopMostViewControllerReturnsAnEmptyTabControllerWithoutRecursing() {
        let controller = UITabBarController()

        XCTAssertTrue(controller.topMostViewController() === controller)
    }
}
#endif
