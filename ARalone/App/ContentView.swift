//
//  ContentView.swift
//  ARalone
//
//  Created by Lukas Eberhart on 12.11.25.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var gameState = GameState()
    @State private var uiState: GameUIState = .menu

    var body: some View {
        ZStack {

            ARViewContainer(
                uiState: $uiState,
                gameState: gameState
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                if uiState != .menu && uiState != .rules {
                    TopHUDBar(
                        canUndo: false,
                        currentPlayer: uiState == .playing
                            ? gameState.currentPlayer
                            : nil,
                        onUndo: { },
                        onMenu: { uiState = .menu }
                    )
                }

                Spacer()
            }

            if uiState == .placingBoard {
                PlacementPromptBanner()
            }

            if uiState == .menu {
                MainMenuView(uiState: $uiState)
            }

            if uiState == .rules {
                RulesView(uiState: $uiState)
            }
        }
    }
}


struct MainMenuView: View {

    @Binding var uiState: GameUIState

    var body: some View {
        VStack(spacing: 24) {

            Text("ARalone")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {

                Button {
                    uiState = .placingBoard
                } label: {
                    Label("Start Game", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    uiState = .rules
                } label: {
                    Label("Rules", systemImage: "book.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(radius: 30)
        .padding()
    }
}

struct RulesView: View {

    @Binding var uiState: GameUIState

    var body: some View {
        VStack(spacing: 20) {

            Text("Rules")
                .font(.title.bold())

            ScrollView {
                Text("""
                • Move one marble per turn  
                • Only adjacent hexes are allowed  
                • Push adjacent enemy marbles off the board if you control more fields behind your marble than them
                • Only in a straight line no gaps
                • Fields get colored by moving a marble to its space
                • Allied marbles can block marbles from getting pushed of the board
                """)
                .font(.body)
            }

            Button("Back") {
                uiState = .menu
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding()
    }
}
