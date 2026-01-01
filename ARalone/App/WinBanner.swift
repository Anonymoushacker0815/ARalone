//
//  WinBanner.swift
//  ARalone
//
//  Created by Lukas on 01.01.26.
//

import SwiftUI

struct WinBanner: View {

    let winner: Player
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            Text("\(winner.displayName) won!")
                .font(.largeTitle.bold())

            Button("OK") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(radius: 20)
    }
}
