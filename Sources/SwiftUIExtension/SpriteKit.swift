//
//  SpriteKit.swift
//  
//
//  Created by Maksym Kulyk on 18.01.2023.
//

import SwiftUI
import SpriteKit

// MARK: - Pridge Protocols

public protocol SKSceneSwiftUI: SKScene
{
    @MainActor
    func onAppear()
    
    @MainActor
    func onDisappear()
    
    @MainActor
    var options: SpriteView.Options { get }
    
    @MainActor
    var debugOptions: SpriteView.DebugOptions { get }
    
    @MainActor
    var preferredFramesPerSecond: Int { get }
    
    @MainActor
    var transitionInit: SKTransition? { get }
    
    @MainActor
    var isPausedInit: Bool { get }
}

// MARK: - SpriteView

public extension SpriteView
{
    /// Setup callbacks for SwiftUI events such as onAppear and onDisappear
    @inlinable @ViewBuilder @MainActor
    func setup(_ scene: SKSceneSwiftUI) -> some View
    {
        self
            .onAppear {
                scene.onAppear()
            }
            .onDisappear {
                scene.onDisappear()
            }
    }
}
