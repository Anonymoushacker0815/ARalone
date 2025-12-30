//
//  PlacementPromptBanner.swift
//  ARalone
//
//  Created by Lukas on 30.12.25.
//

import SwiftUI

struct PlacementPromptBanner: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 110) // clears HUD area

            Text("Tap a flat surface to place the board")
                .font(.callout.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 6)

            Spacer()
        }
        .transition(.opacity)
    }
}
