//
//  PageViewProgressBar.swift
//  ProgrammaticPageView
//
//  Created by Joshua Toro on 10/10/24.
//

import SwiftUI

/// A SwiftUI view that displays a progress bar for page views, including smooth transitions between pages.
struct PageViewProgressBar: View {
    
    /// The index of the currently displayed page.
    var currentIndex: Int
    /// The total number of pages in the view.
    var pageCount: Int
    
    /// Represents the direction of the loop transition when moving between the first and last pages.
    private enum LoopDirection {
        case forward, backward
    }
    
    /// The progress of the main bar, representing the current page position.
    @State private var mainBarProgress: CGFloat = 0.0
    /// The total width of the progress bar.
    @State private var progressBarWidth: CGFloat = 0.0
    /// The current direction of the loop transition, if any.
    @State private var loopDirection: LoopDirection?
    /// Tracks pending index changes during rapid backwards transitions.
    @State private var pendingIndexChange: Int = 0
    /// Indicates whether a transition animation is currently in progress.
    @State private var isTransitioning: Bool = false
    /// The progress of the transition bar during loop animations.
    @State private var transitionBarProgress: CGFloat = 1.0
    
    /// The index of the last page in the view.
    private var lastPageIndex: Int {
        max(pageCount - 1, 0)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Capsule()
                .frame(width: progressBarWidth * mainBarProgress)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isTransitioning {
                Capsule()
                    .frame(width: progressBarWidth * transitionBarProgress)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .foregroundStyle(.white)
        .frame(height: 8)
        .background(.tertiary)
        .clipShape(.capsule)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            progressBarWidth = width
        }
        .onChange(of: pageCount, initial: true) {
            updateMainBarProgress()
        }
        .onChange(of: currentIndex) { oldIndex, newIndex in
            handlePageChange(from: oldIndex, to: newIndex)
        }
    }
    
    // MARK: - Private Methods
    
    /// Updates the progress of the main bar.
    /// - Parameter increment: The number of increments to add to the current index.
    private func updateMainBarProgress(by increment: Int = 1) {
        guard pageCount > 0 else { return }
        mainBarProgress = CGFloat(currentIndex + increment) / CGFloat(pageCount)
    }
    
    /// Handles changes in the current page index, managing transitions and updates.
    /// - Parameters:
    ///   - oldValue: The previous page index.
    ///   - newValue: The new page index.
    private func handlePageChange(from oldValue: Int, to newValue: Int) {
        guard pageCount > 0 else { return }
        let adjustedOldIndex = oldValue.clamped(to: 0...lastPageIndex)
        let adjustedNewIndex = newValue.clamped(to: 0...lastPageIndex)
        
        if adjustedNewIndex == 0 && adjustedOldIndex == lastPageIndex {
            animateProgressTransition(.forward)
        } else if adjustedNewIndex == lastPageIndex && adjustedOldIndex == 0 {
            animateProgressTransition(.backward)
        } else {
            animateMainBarUpdate()
        }
    }
    
    /// Animates the progress bar transition when looping between first and last pages.
    /// - Parameter direction: The direction of the loop transition.
    private func animateProgressTransition(_ direction: LoopDirection) {
        if direction == .forward {
            mainBarProgress = 0
            transitionBarProgress = 1
            isTransitioning = true
            withAnimation {
                transitionBarProgress = 0
            } completion: {
                isTransitioning = false
                guard mainBarProgress == 0 else { return }
                animateMainBarUpdate()
            }
        } else {
            loopDirection = direction
            withAnimation { mainBarProgress = 0 }
            transitionBarProgress = 0
            isTransitioning = true
            withAnimation {
                transitionBarProgress = 1
            } completion: {
                mainBarProgress = 1
                withAnimation { updateMainBarProgress(by: pendingIndexChange) }
                pendingIndexChange = 1
                loopDirection = nil
                isTransitioning = false
            }
        }
    }
    
    /// Animates a regular progress update for the main bar.
    private func animateMainBarUpdate() {
        // If transitioning backward rapidly, cache changes to avoid animation conflicts
        if loopDirection == .backward {
            pendingIndexChange -= 1
            return
        }
        withAnimation {
            updateMainBarProgress()
        }
    }
}

// MARK: - Extensions

private extension Comparable {
    /// Clamps the value within the given range.
    /// - Parameter limits: The range to clamp the value within.
    /// - Returns: The clamped value.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
