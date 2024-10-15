// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A view that displays a pager of subviews, allowing users to navigate between them programmatically with custom transitions.
public struct PageView<Content: View, Indicator: View>: View {
    
    /// Creates a pager view with the specified parameters.
    /// - Parameters:
    ///   - index: A binding to the current index of the pager.
    ///   - loops: A Boolean value indicating whether the pager should loop from the last item back to the first.
    ///   - content: A view builder that creates the content of the pager.
    ///   - indicator: A view builder that takes a `PageViewIndicator` and returns a custom indicator view. Use this to directly modify or replace the default indicator.
    public init(
        index: Binding<Int>,
        loops: Bool = false,
        @ViewBuilder content: () -> Content,
        @ViewBuilder indicator: @escaping (PageViewIndicator) -> Indicator
    ) {
        self._externalIndex = index
        self.isLooping = loops
        self.content = content()
        self.indicatorProxy = indicator
    }
    
    /// Creates a pager view with the specified parameters and no custom indicator.
    /// - Parameters:
    ///   - index: A binding to the current index of the pager.
    ///   - loops: A Boolean value indicating whether the pager should loop from the last item back to the first.
    ///   - content: A view builder that creates the content of the pager.
    public init(
        index: Binding<Int>,
        loops: Bool = false,
        @ViewBuilder content: () -> Content
    ) where Indicator == EmptyView {
        self._externalIndex = index
        self.isLooping = loops
        self.content = content()
        self.indicatorProxy = nil
    }
    
    /// A binding to the current index of the pager.
    @Binding public var externalIndex: Int
    /// A Boolean value indicating whether the pager should loop from the last item back to the first.
    public var isLooping: Bool
    /// The content of the pager.
    @ViewBuilder public var content: Content
    /// A closure for custom modification of the page view indicator. If `nil`, visibility is controlled by `pageViewIndicatorVisibility()`.
    public var indicatorProxy: ((PageViewIndicator) -> Indicator)?
    
    @State private var internalIndex: Int = 0
    @State private var numberOfSubviews: Int = 0
    @State private var isMovingForward: Bool = true
    @State private var isIgnoringChange: Bool = false
    @State private var isInitialPageSet: Bool = false
    
    private var defaultPage: Page?
    private var forwardTransition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    private var backwardTransition: AnyTransition = .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    private var animation: Animation? = .default
    private var indicatorStyle: PageViewIndicatorStyle = .dotIndicator
    private var isDragNavigationEnabled: Bool = false
    private var feedback: SensoryFeedback? = .impact
    private var isShowingIndicator: Bool = false
    private var indexSymbol: String = "circle.fill"
    private var symbolSpacing: PageViewIndicatorSymbolSpacing = .default
    private var indicatorOffset: CGFloat = 0
    private var indicatorSize: PageViewIndicatorSize = .regular
    private var indicatorLongPressAction: (() -> Void)?
    private var indicatorTapAction: (() -> Void)?
    private var indicatorBackgroundStyle: AnyShapeStyle? = AnyShapeStyle(Material.regular)
    
    private var transition: AnyTransition {
        isMovingForward ? forwardTransition : backwardTransition
    }
    
    public var body: some View {
        
        let indicator = PageViewIndicator(
            subviewCount: numberOfSubviews,
            externalIndex: $externalIndex,
            internalIndex: internalIndex,
            style: indicatorStyle,
            isDragNavigationEnabled: isDragNavigationEnabled,
            indexSymbol: indexSymbol,
            symbolSpacing: symbolSpacing,
            symbolSize: indicatorSize,
            indicatorBackgroundStyle: indicatorBackgroundStyle,
            indicatorTapAction: indicatorTapAction,
            indicatorLongPressAction: indicatorLongPressAction)
        
        ZStack(alignment: .bottom) {
            Group(subviews: content) { subviews in
                ForEach(Array(subviews.enumerated()), id: \.offset) { index, subview in
                    if index == internalIndex {
                        subview
                            .transition(transition)
                            .onAppear { numberOfSubviews = subviews.count }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Group {
                if let proxy = indicatorProxy {
                    proxy(indicator)
                } else if isShowingIndicator {
                    indicator
                }
            }
            .padding(.bottom, indicatorOffset)
        }
        .sensoryFeedback(trigger: internalIndex) { _, _ in
            return isInitialPageSet ? feedback : nil
        }
        .task { @MainActor in
            isIgnoringChange = true
            if externalIndex != 0 {
                let maxIndex = numberOfSubviews - 1
                let clampedIndex = min(max(externalIndex, 0), maxIndex)
                updateIndex(to: clampedIndex)
            } else if defaultPage == .first {
                updateIndex(to: 0)
            } else if defaultPage == .last {
                updateIndex(to: numberOfSubviews - 1)
            }
            isIgnoringChange = false
            try? await Task.sleep(for: .seconds(0.25))
            isInitialPageSet = true
        }
        .onChange(of: externalIndex) { oldIndex, newIndex in
            guard !isIgnoringChange else {
                isIgnoringChange = false
                return
            }
            
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
                    isIgnoringChange = true
                    isMovingForward = true
                } else if oldIndex == 0 && adjustedNewIndex == maxIndex {
                    isIgnoringChange = true
                    isMovingForward = false
                } else {
                    isMovingForward = adjustedNewIndex > oldIndex
                }
            } else {
                isMovingForward = adjustedNewIndex > oldIndex
            }
            
            withAnimation(animation) {
                updateIndex(to: adjustedNewIndex)
            }
        }
    }

    private func updateIndex(to newIndex: Int) {
        internalIndex = newIndex
        externalIndex = newIndex
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
    public func defaultPage(_ page: Page) -> Self {
        var copy = self
        copy.defaultPage = page
        return copy
    }
    
    /// Configures a long press action for the page view indicator.
    /// - Parameter action: A closure to be executed when the page view indicator is long-pressed.
    /// - Returns: A modified instance of PageView with the specified long press action.
    public func pageViewIndicatorLongPressAction(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.indicatorLongPressAction = action
        return copy
    }
    
    /// Configures a tap action for the page view indicator.
    /// - Parameter action: A closure to be executed when the page view indicator is tapped.
    /// - Returns: A modified instance with the specified tap action.
    public func pageViewIndicatorTapAction(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.indicatorTapAction = action
        return copy
    }
    
    /// Sets the haptic feedback for page transitions in the page view.
    /// - Parameter feedback: The haptic feedback to play when the current page changes. Set to `nil` to disable feedback.
    /// - Returns: A modified instance of PageView with the specified feedback configuration.
    public func pageViewFeedback(_ feedback: SensoryFeedback?) -> Self {
        var copy = self
        copy.feedback = feedback
        return copy
    }
    
    /// Configures the page view indicator's visibility and interaction.
    /// - Parameters:
    ///   - visibility: Determines whether the indicator is visible.
    ///   - dragNavigationEnabled: A Boolean value that determines whether dragging on the indicator changes the current page. Default is `false`.
    /// - Returns: A modified instance of PageView with the specified indicator configuration.
    public func pageViewIndicator(visibility: Visibility, dragNavigationEnabled: Bool = false) -> Self {
        var copy = self
        copy.isShowingIndicator = visibility == .visible
        copy.isDragNavigationEnabled = dragNavigationEnabled
        return copy
    }
    
    /// Sets the visual style of the page view indicator.
    /// - Parameter style: The style to apply to the page view indicator.
    /// - Returns: A modified instance of PageView with the specified indicator style.
    public func pageViewIndicatorStyle(_ style: PageViewIndicatorStyle) -> Self {
        var copy = self
        copy.indicatorStyle = style
        return copy
    }
    
    /// Configures the page view indicator's symbol, size, and spacing.
    /// - Parameters:
    ///   - symbol: The SF Symbol name to use for page indicators. Default is "circle.fill".
    ///   - size: The size of the page indicator symbols. Default is `.regular`.
    ///   - spacing: The spacing between page indicator symbols. Default is `.default`.
    /// - Returns: A modified instance of PageView with the specified indicator symbol, size, and spacing.
    public func pageViewIndicatorIndexSymbol(
        _ symbol: String = "circle.fill",
        size: PageViewIndicatorSize = .regular,
        spacing: PageViewIndicatorSymbolSpacing = .default
    ) -> Self {
        var copy = self
        copy.indexSymbol = symbol
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
