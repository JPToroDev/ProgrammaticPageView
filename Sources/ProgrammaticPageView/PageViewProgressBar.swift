//
//  PageViewIndicatorSymbolSpacing.swift
//  ProgrammaticPageView
//
//  Created by JP Toro on 10/8/24.
//

import SwiftUI

/// A SwiftUI view that displays a progress bar for page views, including smooth transitions between pages.
struct PageViewProgressBar: View {
    
    /// The index of the currently displayed page.
    var currentIndex: Int
    /// The total number of pages in the view.
    var pageCount: Int
    
    private enum AnimationPhase {
        case updateProgress
        case clearProgressFromTrailing
        case switchAlignmentToLeading
        case setProgressFromLeading
        case clearProgressFromLeading
        case switchAlignmentToTrailing
        case setProgressFromTrailing
        
        var alignment: Alignment {
            switch self {
            case .updateProgress, .switchAlignmentToLeading, .setProgressFromLeading, .clearProgressFromLeading:
                return .leading
            case .clearProgressFromTrailing, .switchAlignmentToTrailing, .setProgressFromTrailing:
                return .trailing
            }
        }
    }
    
    @State private var progressBarWidth: CGFloat = 0.0
    @State private var isTransitioning: Bool = false
    @State private var animationPhases: [AnimationPhase] = [.updateProgress]
    
    private var lastPageIndex: Int {
        max(pageCount - 1, 0)
    }
    
    var body: some View {
        Capsule()
            .fill(.white)
            .phaseAnimator(animationPhases, trigger: isTransitioning) { content, phase in
                content
                    .frame(width: progressBarWidth * progress(for: phase))
                    .frame(maxWidth: .infinity, alignment: phase.alignment)
            } animation: { phase in
                switch phase {
                case .switchAlignmentToLeading, .switchAlignmentToTrailing:
                    return nil
                default:
                    return .default
                }
            }
            .frame(height: 8)
            .background(.tertiary)
            .clipShape(.capsule)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                progressBarWidth = width
            }
            .onChange(of: currentIndex) { oldIndex, newIndex in
                handlePageChange(from: oldIndex, to: newIndex)
            }
    }
    
    private func progress(for phase: AnimationPhase) -> CGFloat {
        guard pageCount > 0 else { return 0 }
        switch phase {
        case .updateProgress, .setProgressFromLeading:
            return CGFloat(currentIndex + 1) / CGFloat(pageCount)
        case .clearProgressFromTrailing, .clearProgressFromLeading, .switchAlignmentToLeading, .switchAlignmentToTrailing:
            return 0
        case .setProgressFromTrailing:
            return 1
        }
    }
    
    private func handlePageChange(from oldIndex: Int, to newIndex: Int) {
        guard pageCount > 0 else { return }
        let adjustedOldIndex = oldIndex.clamped(to: 0...lastPageIndex)
        let adjustedNewIndex = newIndex.clamped(to: 0...lastPageIndex)
        
        if adjustedNewIndex == 0 && adjustedOldIndex == lastPageIndex {
            animateProgressTransition(toStart: true)
        } else if adjustedNewIndex == lastPageIndex && adjustedOldIndex == 0 {
            animateProgressTransition(toStart: false)
        }
    }
    
    private func animateProgressTransition(toStart: Bool) {
        if toStart {
            animationPhases = [.updateProgress, .clearProgressFromTrailing, .switchAlignmentToLeading, .setProgressFromLeading]
        } else {
            animationPhases = [.updateProgress, .clearProgressFromLeading, .switchAlignmentToTrailing, .setProgressFromTrailing]
        }
        isTransitioning.toggle()
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
