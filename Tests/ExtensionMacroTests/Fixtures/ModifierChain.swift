//
//  ModifierChain.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

import SwiftUI

#if FIXED
extension Color {
    static var p_missingColor: Self { .purple }
}
#endif

struct P_CompilerFixture: View {
    #if DIAGNOSTIC
    @debug_view
    #endif
    var body: some View {
        VStack {
            Text("Sample")
                .font(.headline)
                .padding()
                .foregroundStyle(.primary)
                .background(.thinMaterial)
                .cornerRadius(12)
                .shadow(radius: 2)
                .opacity(0.9)
                .padding(4)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .padding(.horizontal, 2)
                .border(Color.gray)
                .scaleEffect(1)
                .rotationEffect(.degrees(0))
                .font(.headline)
                .padding()
                .foregroundStyle(.primary)
                .background(.thinMaterial)
                .cornerRadius(12)
                .shadow(radius: 2)
                .opacity(0.9)
                .padding(4)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .padding(.horizontal, 2)
                .border(Color.gray)
                .scaleEffect(1)
                .rotationEffect(.degrees(0))
                .font(.headline)
                .padding()
                .foregroundStyle(.primary)
                .background(.thinMaterial)
                .cornerRadius(12)
                .shadow(radius: 2)
                .opacity(0.9)
                .padding(4)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .padding(.horizontal, 2)
                .border(Color.gray)
                .scaleEffect(1)
                .rotationEffect(.degrees(0))
                .foregroundStyle(Color.p_missingColor)
        }
    }
}
