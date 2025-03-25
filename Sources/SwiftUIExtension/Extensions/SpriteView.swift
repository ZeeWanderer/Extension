//
//  SpriteView.swift
//  
//
//  Created by zeewanderer on 21.05.2024.
//

import SwiftUI
import SpriteKit

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
