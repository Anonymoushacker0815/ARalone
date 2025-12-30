//
//  TopHUDBar.swift
//  ARalone
//
//  Created by Lukas on 30.12.25.
//

import SwiftUI

struct TopHUDBar: View {

    let canUndo: Bool
    let currentPlayer: Player?
    let onUndo: () -> Void
    let onMenu: () -> Void

    var body: some View {
        HStack {

            // MARK: - Undo
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3)
            }
            .disabled(!canUndo)
            .opacity(canUndo ? 1 : 0.4)

            Spacer()

            // MARK: - Turn Indicator
            if let player = currentPlayer {
                HStack(spacing: 6) {
                    Circle()
                        .fill(player.uiColor)
                        .frame(width: 8, height: 8)

                    Text("\(player.displayName)’s Turn")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(Capsule())
            } else {
                EmptyView()
            }

            Spacer()

            // MARK: - Menu
            Button(action: onMenu) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.top, 1)
        .shadow(radius: 10)
    }
}
