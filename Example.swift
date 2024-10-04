//
//  Example.swift
//  SwiftCarousel
//
//  Created by JP Toro on 10/4/24.
//

import SwiftUI

struct ContentView: View {
  @State private var index = 0
  
  var body: some View {
    ZStack(alignment: .bottom) {
      PageView(index: $index, loops: true) {
        Color.red
        Color.blue
        Color.purple
        Color.yellow
        Color.green
        Color.orange
        Color.indigo
      } //: Carousel
      HStack {
        Button("Back") {
          index -= 1
        }
        Button("Forward") {
          index += 1
        }
        Rectangle()
          .frame(width: 1, height: 20)
        Button("Yellow") {
          index = 3
        }
      } //: HStack
      .padding()
      .background(.white, in: .rect(cornerRadius: 12, style: .continuous))
      .padding(.bottom, 25)
    } //: ZStack
    .ignoresSafeArea(edges: [.vertical])
  }
}

#Preview {
  ContentView()
}
