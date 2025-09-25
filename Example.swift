//
// Example.swift
// ProgrammaticPageView
// https://github.com/JPToroDev/ProgrammaticPageView
// See LICENSE for license information.
// © 2024 J.P. Toro
//

import SwiftUI

struct ContentView: View {
    @State private var pageIndex = 0
    @State private var hasAcceptedTerms = false

    var body: some View {
        PageView(index: $pageIndex) {
            page1
            page2
            page3
        }
        .pageViewIndicatorVisibility(.visible)
        .pageViewIndicatorIndexSymbol("square.fill", size: .large)
        .pageViewIndicatorStyle(.dotIndicator)
        .pageViewIndicatorBackgroundStyle(.blue)
        .pageViewIndicatorLongPressAction {
            print("Some action")
        }
    }

    private var page1: some View {
        VStack {
            Text("Welcome!")
            Button("Next") { pageIndex += 1 }
                .buttonStyle(.borderedProminent)
        }
    }

    private var page2: some View {
        List {
            Text("Please accept terms and conditions.")
            Toggle("Accept Terms", isOn: $hasAcceptedTerms)

            Section {
                Button("Next") { pageIndex += 1 }
                    .disabled(!hasAcceptedTerms)
            }
        }
    }

    private var page3: some View {
        VStack {
            Text("All Set!")
            Button("Get Started") {
                // Proceed to main app
            }
            Button("Restart") {
               pageIndex = 0
            }
        }
    }
}

#Preview {
    ContentView()
}
