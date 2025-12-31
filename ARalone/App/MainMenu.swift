//
//  MainMenu.swift
//  ARalone
//
//  Created by Lukas on 30.12.25.
//

import SwiftUI

struct MainMenuView: View {

    @Binding var uiState: GameUIState
    let hasStarted: Bool
    let onStartOrRestart: () -> Void
    let onReplaceBoard: () -> Void
    
    @State private var showRestartConfirm = false
    @State private var showReplaceConfirm = false

    var body: some View {
        VStack(spacing: 24) {

            Text("ARalone")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {

                Button {
                    if hasStarted {
                        showRestartConfirm = true
                    } else {
                        onStartOrRestart()
                    }
                } label: {
                    Label(
                        hasStarted ? "Restart Game" : "Start Game",
                        systemImage: hasStarted ? "arrow.clockwise" : "play.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .confirmationDialog(
                    "Restart Game?",
                    isPresented: $showRestartConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Restart Game", role: .destructive) {
                        onStartOrRestart()
                    }

                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The current game will be lost.")
                }

                Button {
                    uiState = .rules
                } label: {
                    Label("Rules", systemImage: "book.fill")
                }
                .buttonStyle(.bordered)
            
                Button(role: .destructive) {
                    showReplaceConfirm = true
                } label: {
                    Label("Replace Board", systemImage: "arrow.clockwise")
                }

            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(radius: 30)
        .padding()
        .confirmationDialog(
            "Replace Board?",
            isPresented: $showReplaceConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace Board", role: .destructive) {
                onReplaceBoard()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the current board and reset the game.")
        }
    }
}
