//
//  ContentView.swift
//  ARalone
//
//  Created by Lukas Eberhart on 12.11.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .center) {
                Text("ARalone — Tap a flat surface to place the hex board")
                    .font(.callout)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.top, 40)

                Spacer()
            }
        }
    }
}

