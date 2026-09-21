//
//  FeedbackConcurrencyTests.swift
//
//
//  Created by zeewanderer on 10.09.2026.
//

import XCTest
import UIKitExtension

#if canImport(UIKit)
import UIKit

@MainActor
final class FeedbackConcurrencyTests: XCTestCase
{
    func testAwaitedFeedbackRunsOnTheMainActorInTheCallingTask() async throws
    {
        let taskID = try XCTUnwrap(withUnsafeCurrentTask { $0?.hashValue })
        var count = 0
        FeedbackHelper.set_dynamic_preferences(vibration: {
            MainActor.assertIsolated()
            XCTAssertEqual(withUnsafeCurrentTask { $0?.hashValue }, taskID)
            count += 1
            return false
        }, sound: {
            MainActor.assertIsolated()
            XCTAssertEqual(withUnsafeCurrentTask { $0?.hashValue }, taskID)
            count += 1
            return false
        })
        defer { FeedbackHelper.set_dynamic_preferences(vibration: { true }, sound: { true }) }

        await FeedbackHelper.prepare_selection_generator()
        await FeedbackHelper.prepare_notification_generator()
        await FeedbackHelper.prepare_impact_generator(.light)
        await FeedbackHelper.prepare_impact_generators()
        await FeedbackHelper.play_button_sound()
        await FeedbackHelper.selectionChanged()
        await FeedbackHelper.notificationOccurred(.success)
        await FeedbackHelper.impactOccurred(.medium)
        await FeedbackHelper.impactOccurred(.heavy, intensity: 0.5)

        XCTAssertEqual(count, 9)
    }
}
#endif
