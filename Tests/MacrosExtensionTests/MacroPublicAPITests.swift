//
//  MacroPublicAPITests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest
import SwiftData
import MacrosExtension

@ModelSnapshot
@Model
private final class MacroSnapshotChild
{
    var value: Int

    init(value: Int)
    {
        self.value = value
    }
}

@ModelSnapshot
@Model
private final class MacroSnapshotParent
{
    @Relationship
    var child: MacroSnapshotChild

    init(child: MacroSnapshotChild)
    {
        self.child = child
    }
}

@ActorProtocol
private protocol MacroDataService: Sendable
{
    associatedtype Item: Sendable
    var context: Int { get }
    subscript(index: Int) -> Item { get }
    func readContext() -> Int
}

private struct MacroDataServiceImplementation: MacroDataService
{
    typealias Item = Int
    var context: Int { 42 }
    subscript(index: Int) -> Int { context + index }
    func readContext() -> Int { context }
}

private actor MacroDataServiceActorImplementation: MacroDataServiceActor
{
    typealias Item = Int
    let context: Int = 43
    subscript(index: Int) -> Int { context + index }
    func readContext() -> Int { context }
}

private func macroActorItem<Service: MacroDataServiceActor>(
    _ service: Service,
    at index: Int
) async -> Service.Item
{
    await service[index]
}

final class MacroPublicAPITests: XCTestCase
{
    func testGeneratedModelSnapshotAPICompilesAndRuns()
    {
        let child = MacroSnapshotChild(value: 7)
        let parent = MacroSnapshotParent(child: child)

        XCTAssertEqual(parent.snapshot.child.value, 7)
    }

    func testGeneratedActorProtocolAPICompilesAndRuns() async
    {
        let service: any MacroDataService = MacroDataServiceImplementation()
        let actorImplementation = MacroDataServiceActorImplementation()
        let actorService: any MacroDataServiceActor = actorImplementation
        let actorContext = await actorService.context
        let actorReadContext = await actorService.readContext()
        let actorItem = await macroActorItem(actorImplementation, at: 2)

        XCTAssertEqual(service.readContext(), 42)
        XCTAssertEqual(actorContext, 43)
        XCTAssertEqual(actorReadContext, 43)
        XCTAssertEqual(actorItem, 45)
    }
}
