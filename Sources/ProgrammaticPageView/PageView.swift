// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A view that displays a pager of subviews, allowing users to navigate between them programmatically with custom transitions.
public struct PageView<Content: View>: View {
    
    /// Creates a pager view with the specified parameters.
    /// - Parameters:
    ///   - index: A binding to the current index of the pager.
    ///   - loops: A Boolean value indicating whether the pager should loop from the last item back to the first.
    ///   - content: A view builder that creates the content of the pager.
    public init(
        index: Binding<Int>,
        loops: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self._index = index
        self.isLooping = loops
        self.content = content()
    }
    
    /// A binding to the current index of the pager.
    @Binding public var index: Int
    /// A Boolean value indicating whether the pager should loop from the last item back to the first.
    public var isLooping: Bool
    /// The content of the pager.
    @ViewBuilder public var content: Content
    
    @State private var currentIndex: Int = 0
    @State private var isMovingForward: Bool = true
    @State private var isIgnoringChange: Bool = false
    @State private var numberOfSubviews = 0
    
    private var defaultPage: Page?
    private var forwardTransition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    private var backwardTransition: AnyTransition = .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    private var animation: Animation? = .default
    private var isInteractionEnabled: Bool = false
    private var feedback: SensoryFeedback? = .impact
    private var isShowingIndicator: Bool = false
    private var pageSymbol: String = "circle.fill"
    private var symbolSpacing: PageViewIndicatorSymbolSpacing = .default
    private var indicatorOffset: CGFloat = 0
    private var indicatorSize: PageViewIndicatorSize = .regular
    private var indicatorBackgroundStyle: AnyShapeStyle? = AnyShapeStyle(Material.regular)
    
    private var transition: AnyTransition {
        isMovingForward ? forwardTransition : backwardTransition
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            Group(subviews: content) { subviews in
                ForEach(Array(subviews.enumerated()), id: \.offset) { index, subview in
                    if index == currentIndex {
                        subview
                            .transition(transition)
                            .onAppear { numberOfSubviews = subviews.count }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if isShowingIndicator {
                PageViewIndicator(
                    subviewCount: numberOfSubviews,
                    currentIndex: $index,
                    isInteractionEnabled: isInteractionEnabled,
                    feedback: feedback,
                    pageSymbol: pageSymbol,
                    symbolSpacing: symbolSpacing,
                    indicatorSize: indicatorSize,
                    indicatorBackgroundStyle: indicatorBackgroundStyle)
                .padding(.bottom, indicatorOffset)
            }
        }
        .task { @MainActor in
            isIgnoringChange = true
            if index != 0 {
                let maxIndex = numberOfSubviews - 1
                let clampedIndex = min(max(index, 0), maxIndex)
                updateIndex(to: clampedIndex)
            } else if defaultPage == .first {
                updateIndex(to: 0)
            } else if defaultPage == .last {
                updateIndex(to: numberOfSubviews - 1)
            }
            isIgnoringChange = false
        }
        .onChange(of: index) { oldIndex, newIndex in
            guard !isIgnoringChange else { return }
            let maxIndex = numberOfSubviews - 1
            var adjustedNewIndex = newIndex
            
            if isLooping {
                if newIndex < 0 {
                    adjustedNewIndex = maxIndex
                } else if newIndex > maxIndex {
                    adjustedNewIndex = 0
                }
            } else {
                adjustedNewIndex = min(max(newIndex, 0), maxIndex)
            }
            
            if isLooping {
                if oldIndex == maxIndex && adjustedNewIndex == 0 {
                    isMovingForward = true
                } else if oldIndex == 0 && adjustedNewIndex == maxIndex {
                    isMovingForward = false
                } else {
                    isMovingForward = adjustedNewIndex > oldIndex
                }
            } else {
                isMovingForward = adjustedNewIndex > oldIndex
            }
            
            /// Explanation of Task usage
            /// https://stackoverflow.com/questions/77570188/swiftui-dynamic-transition-on-view-insertion-removal
            Task { @MainActor in
                withAnimation(animation) {
                    updateIndex(to: adjustedNewIndex)
                }
            }
        }
    }
    
    private func updateIndex(to newIndex: Int) {
        var adjustedIndex = newIndex
        let maxIndex = numberOfSubviews - 1
        
        if isLooping {
            if newIndex < 0 {
                adjustedIndex = maxIndex
            } else if newIndex > maxIndex {
                adjustedIndex = 0
            }
        } else {
            adjustedIndex = min(max(newIndex, 0), maxIndex)
        }
        
        if adjustedIndex != index {
            currentIndex = adjustedIndex
            index = adjustedIndex
        } else {
            currentIndex = index
        }
    }
}

extension PageView {
    
    /// Sets custom transitions for page changes and an optional animation.
    /// - Parameters:
    ///   - forward: The transition to use when moving to the next page.
    ///   - backward: The transition to use when moving to the previous page.
    ///   - animation: An optional animation to apply to the page transitions.
    /// - Returns: A modified instance of PageView with the specified transitions and animation.
    public func pageTransition(forward: AnyTransition, backward: AnyTransition, animation: Animation? = .default) -> Self {
        var copy = self
        copy.forwardTransition = forward
        copy.backwardTransition = backward
        copy.animation = animation
        return copy
    }
    
    /// Sets a single transition for both forward and backward page changes and an optional animation.
    /// - Parameters:
    ///   - transition: The transition to use for both forward and backward page changes. If `nil`, the default transition is used.
    ///   - animation: An optional animation to apply to the page transition.
    /// - Returns: A modified instance of PageView with the specified transition and animation.
    public func pageTransition(_ transition: AnyTransition? = nil, animation: Animation? = .default) -> Self {
        var copy = self
        if let transition {
            copy.forwardTransition = transition
            copy.backwardTransition = transition
        }
        copy.animation = animation
        return copy
    }
    
    /// Sets the default page without an animation. This will be overridden if `index` is not zero.
    /// - Parameter page: The default page to display.
    /// - Returns: A modified instance of PageView with the default page set.
    public func defaultPage(_ page: Page = .first) -> Self {
        var copy = self
        copy.defaultPage = page
        return copy
    }
    
    /// Configures the page view indicator's visibility and interaction.
    /// - Parameters:
    ///   - visibility: Determines whether the indicator is visible. Default is `.visible`.
    ///   - interactionEnabled: A Boolean value that determines whether tapping on indicators changes the current page. Default is `false`.
    ///   - feedback: The haptic feedback to play when the current page changes. Set to `nil` to disable feedback. Default is `.impact`.
    /// - Returns: A modified instance of PageView with the specified indicator configuration.
    public func pageViewIndicator(visibility: Visibility = .visible, interactionEnabled: Bool = false, feedback: SensoryFeedback? = .impact) -> Self {
        var copy = self
        copy.isShowingIndicator = visibility == .visible
        copy.isInteractionEnabled = interactionEnabled
        copy.feedback = feedback
        return copy
    }
    
    /// Configures the page view indicator's symbol, size, and spacing.
    /// - Parameters:
    ///   - pageSymbol: The SF Symbol name to use for page indicators. Default is "circle.fill".
    ///   - size: The size of the page indicator symbols. Default is `.regular`.
    ///   - spacing: The spacing between page indicator symbols. Default is `.default`.
    /// - Returns: A modified instance of PageView with the specified indicator symbol, size, and spacing.
    public func pageViewIndicatorSymbol(
        _ pageSymbol: String = "circle.fill",
        size: PageViewIndicatorSize = .regular,
        spacing: PageViewIndicatorSymbolSpacing = .default
    ) -> Self {
        var copy = self
        copy.pageSymbol = pageSymbol
        copy.indicatorSize = size
        copy.symbolSpacing = spacing
        return copy
    }
    
    /// Sets a custom background style for the page view indicator.
    /// - Parameter background: A shape style to be used as the background for the indicator.
    ///   If `nil`, the background will be removed.
    /// - Returns: A modified instance of PageView with the specified indicator background style.
    public func pageViewIndicatorBackground<S: ShapeStyle>(_ background: S?) -> Self {
        var copy = self
        copy.indicatorBackgroundStyle = background.map { AnyShapeStyle($0) }
        return copy
    }
    
    /// Sets a custom background style for the page view indicator.
    /// - Parameter background: Pass `nil` to this parameter to remove the background.
    /// - Returns: A modified instance of PageView with a clear indicator background.
    public func pageViewIndicatorBackground(_ background: ExpressibleByNilLiteral?) -> Self {
        var copy = self
        copy.indicatorBackgroundStyle = nil
        return copy
    }
    
    /// Sets the vertical offset of the page view indicator from the bottom of the view.
    /// - Parameter offset: The distance in points to offset the indicator from the bottom.
    /// - Returns: A modified instance of PageView with the specified indicator offset.
    public func pageViewIndicatorOffset(_ offset: CGFloat) -> Self {
        var copy = self
        copy.indicatorOffset = offset
        return copy
    }
}
