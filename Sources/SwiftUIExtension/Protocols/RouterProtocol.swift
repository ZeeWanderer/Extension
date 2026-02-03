//
//  RouterProtocol.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

import SwiftUI

/// Base router contract with multi-path support and view registration.
@MainActor
public protocol RouterProtocol: AnyObject {
    associatedtype Destination: RouterDestination
    associatedtype PathID: Hashable
    
    /// Default path used for single-path routers.
    static var defaultPathID: PathID { get }
    
    /// Registered destination views.
    static var views: [any RouterDestinationView<Destination>.Type] { get }
    
    /// Flat destination -> view type map built from ``views``.
    static var viewTypes: [Destination.Flat: any RouterDestinationView<Destination>.Type] { get }
    
    /// All navigation paths keyed by identifier.
    var paths: [PathID: [Destination]] { get set }
}

public extension RouterProtocol {
    /// Computes flat destination -> view type map from ``views``.
    static func computeViewTypes() -> [Destination.Flat: any RouterDestinationView<Destination>.Type] {
        var map: [Destination.Flat: any RouterDestinationView<Destination>.Type] = [:]
        for viewType in views {
            for flat in viewType.flats {
                precondition(map[flat] == nil, "Duplicate destination registration for \(flat)")
                map[flat] = viewType
            }
        }
        return map
    }
    
    /// Returns a view type for a flat destination.
    static func viewType(for flat: Destination.Flat) -> (any RouterDestinationView<Destination>.Type)? {
        viewTypes[flat]
    }
    
    /// Default path for single-path routers.
    var path: [Destination] {
        get { paths[Self.defaultPathID, default: []] }
        set { paths[Self.defaultPathID] = newValue }
    }
    
    /// Returns path for provided identifier.
    func path(for pathID: PathID) -> [Destination] {
        paths[pathID, default: []]
    }
    
    /// Mutates a path in-place and stores the result.
    func withPath(_ pathID: PathID, _ closure: (inout [Destination]) -> Void) {
        var path = paths[pathID, default: []]
        closure(&path)
        paths[pathID] = path
    }
    
    /// Builds view for a destination using the registered view list.
    func view(for destination: Destination, pathID: PathID? = nil, requester: AnyHashable? = nil) -> AnyView {
        let resolvedPathID = pathID.map { AnyHashable($0) }
        return Self.view(for: destination, pathID: resolvedPathID, requester: requester)
    }
    
    /// Builds view for a destination using the registered view list.
    static func view(for destination: Destination, pathID: AnyHashable? = nil, requester: AnyHashable? = nil) -> AnyView {
        guard let viewType = viewType(for: destination.flat) else {
            assertionFailure("Missing destination registration for \(destination.flat)")
            return AnyView(EmptyView())
        }
        
        return viewType.makeView(destination: destination, pathID: pathID, requester: requester)
    }
}

// MARK: - Static Path Operations
public extension RouterProtocol {
    static func popAll(_ array: inout [Destination]) {
        array.removeAll(keepingCapacity: true)
    }
    
    @discardableResult
    static func pop(_ array: inout [Destination], amount: Int = 1) -> Bool {
        guard amount <= array.count else { return false }
        array.removeLast(amount)
        return true
    }
    
    @discardableResult
    static func pop(_ array: inout [Destination], to destination: Destination) -> Bool {
        guard let lastIdx = array.lastIndex(of: destination) else { return false }
        let diff = array.endIndex - lastIdx - 1
        if diff > 0 { array.removeLast(diff) }
        return true
    }
    
    @discardableResult
    static func pop(_ array: inout [Destination], to destination: Destination.Flat) -> Bool {
        guard let lastIdx = array.lazy.map(\.flat).lastIndex(of: destination) else { return false }
        let diff = array.endIndex - lastIdx - 1
        if diff > 0 { array.removeLast(diff) }
        return true
    }
    
    static func lastIndex(_ array: [Destination], of destination: Destination) -> [Destination].Index? {
        array.lastIndex(of: destination)
    }
    
    static func lastIndex(_ array: [Destination], of destination: Destination.Flat) -> [Destination].Index? {
        array.lazy.map(\.flat).lastIndex(of: destination)
    }
    
    static func push(_ destination: Destination, to array: inout [Destination], options: RouterPushOptions = []) {
        if options.contains(.popToExisting) {
            if options.contains(.flatComparison) {
                if let _ = lastIndex(array, of: destination.flat) {
                    _ = pop(&array, to: destination.flat)
                    return
                }
            } else {
                if let _ = lastIndex(array, of: destination) {
                    _ = pop(&array, to: destination)
                    return
                }
            }
        }
        
        array.append(destination)
    }
}

// MARK: - Instance Path Operations
public extension RouterProtocol {
    func popAll() {
        popAll(Self.defaultPathID)
    }
    
    func popAll(_ pathID: PathID) {
        withPath(pathID) { Self.popAll(&$0) }
    }
    
    func pop(_ pathID: PathID, amount: Int = 1) -> Bool {
        var popped = false
        withPath(pathID) { popped = Self.pop(&$0, amount: amount) }
        return popped
    }
    
    func pop(_ pathID: PathID, to destination: Destination) -> Bool {
        var popped = false
        withPath(pathID) { popped = Self.pop(&$0, to: destination) }
        return popped
    }
    
    func push(_ destination: Destination, to pathID: PathID = Self.defaultPathID, options: RouterPushOptions = []) {
        withPath(pathID) { Self.push(destination, to: &$0, options: options) }
    }
}

public extension RouterProtocol {
    func pop(_ pathID: PathID, to destination: Destination.Flat) -> Bool {
        var popped = false
        withPath(pathID) { popped = Self.pop(&$0, to: destination) }
        return popped
    }
}
