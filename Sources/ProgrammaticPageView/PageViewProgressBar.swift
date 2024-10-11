//
//  PageViewProgressBar.swift
//  ProgrammaticPageView
//
//  Created by Joshua Toro on 10/10/24.
//

import SwiftUI

/// A SwiftUI view that displays a progress bar for page views.
struct PageViewProgressBar: View {
    
    /// The current page index.
    var currentIndex: Int
    /// The total number of pages.
    var totalPages: Int
    
    private enum Direction {
        case forward, backward
    }
    
    @State private var progress: CGFloat = 0.0
    @State private var barWidth: CGFloat = 0.0
    @State private var alignment: Alignment = .leading
    @State private var loopDirection: Direction?
    @State private var cachedIncrement: Int = 0
    
    private let animation: Animation = .default
    
    private var maxIndex: Int {
        max(totalPages - 1, 0)
    }
    
    var body: some View {
        Capsule()
            .foregroundStyle(.white)
            .frame(width: barWidth * progress, height: 8)
            .frame(maxWidth: .infinity, alignment: alignment)
            .background(.tertiary)
            .clipShape(.capsule)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                barWidth = width
            }
            .onAppear { updateProgress() }
            .onChange(of: currentIndex) { oldIndex, newIndex in
                handleIndexChange(oldValue: oldIndex, newValue: newIndex)
            }
    }
    
    /// Updates the progress of the bar.
    /// - Parameter increment: The number of increments to add to the current index.
    private func updateProgress(by increment: Int = 1) {
        guard totalPages > 0 else { return }
        progress = CGFloat(currentIndex + increment) / CGFloat(totalPages)
    }
    
    /// Handles changes in the current index.
    /// - Parameters:
    ///   - oldValue: The previous index value.
    ///   - newValue: The new index value.
    private func handleIndexChange(oldValue: Int, newValue: Int) {
        guard totalPages > 0 else { return }
        let adjustedOldIndex = oldValue.clamped(to: 0...maxIndex)
        let adjustedNewIndex = newValue.clamped(to: 0...maxIndex)
        
        if adjustedNewIndex == 0 && adjustedOldIndex == maxIndex {
            animateProgressReset(.trailing)
        } else if adjustedNewIndex == maxIndex && adjustedOldIndex == 0 {
            animateProgressReset(.leading)
        } else {
            animateProgressUpdate()
        }
    }
    
    /// Animates the progress bar reset.
    /// - Parameter alignment: The new alignment for the progress bar.
    private func animateProgressReset(_ alignment: Alignment) {
        loopDirection = alignment == .trailing ? .forward : .backward
        self.alignment = alignment
        withAnimation(animation) {
            progress = 0.0
        } completion: {
            let newProgress = alignment == .trailing ? 1.0 / CGFloat(totalPages) : 1.0
            /// If looping is enabled and the index is increasing rapidly, this progress
            /// might be outdated by the time this handler is called.
            if alignment == .trailing {
                guard newProgress > progress else { return }
            }
            self.alignment = alignment == .leading ? .trailing : .leading
            withAnimation(animation) {
                progress = newProgress
            } completion: {
                loopDirection = nil
                if cachedIncrement != 0 {
                    self.alignment = .leading
                    withAnimation(animation) {
                        updateProgress(by: cachedIncrement + 1)
                        cachedIncrement = 0
                    }
                }
            }
        }
    }
    
    /// Animates a regular progress update.
    private func animateProgressUpdate() {
        /// If looping is enabled and the index is decreasing rapidly,
        /// this method will block the second animation completion handler above.
        /// So we'll cache the changes and execute them in the handler.
        if loopDirection == .backward {
            cachedIncrement -= 1
            return
        }
        alignment = .leading
        withAnimation(animation) {
            updateProgress()
        }
    }
}

private extension Comparable {
    /// Clamps the value within the given range.
    /// - Parameter limits: The range to clamp the value within.
    /// - Returns: The clamped value.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
