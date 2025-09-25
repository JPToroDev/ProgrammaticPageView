//
// PageView.swift
// ProgrammaticPageView
// https://github.com/JPToroDev/ProgrammaticPageView
// See LICENSE for license information.
// © 2024 J.P. Toro
//

import SwiftUI

/// A view that displays a pager of subviews, allowing users to navigate
/// between them programmatically with custom transitions.
public struct PageView<Content: View, Indicator: View>: View {
    /// A binding to the current index of the pager.
    @Binding var externalIndex: Int

    /// A Boolean value indicating whether the pager should loop
    /// from the last item back to the first.
    var isLooping: Bool

    /// The content of the pager.
    @ViewBuilder var content: Content

    /// A closure for custom modification of the page view indicator.
    /// If `nil`, visibility is controlled by `pageViewIndicatorVisibility()`.
    var indicatorProxy: ((PageViewIndicator) -> Indicator)?

    /// The appearance and behavior of the indicator.
    var indicatorConfiguration: PageViewIndicatorConfiguration = .init()

    @State private var internalIndex: Int = 0
    @State private var numberOfSubviews: Int = 0
    @State private var isMovingForward: Bool = true
    @State private var isIgnoringChange: Bool = false
    @State private var isInitialPageSet: Bool = false

    private var defaultPage: Page?
    private var feedback: SensoryFeedback? = .impact
    private var isShowingIndicator: Bool = false
    private var indicatorOffset: CGFloat = 0
    private var animation: Animation? = .default

    private var forwardTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading))

    private var backwardTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .trailing))

    private var transition: AnyTransition {
        isMovingForward ? forwardTransition : backwardTransition
    }

    /// Creates a pager view with the specified parameters.
    /// - Parameters:
    ///   - index: A binding to the current index of the pager.
    ///   - loops: A Boolean value indicating whether the pager should
    ///   loop from the last item back to the first.
    ///   - content: A view builder that creates the content of the pager.
    ///   - indicator: A view builder that takes a `PageViewIndicator`
    ///   and returns a custom indicator view.
    ///   Use this to directly modify or replace the default indicator.
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
    ///   - loops: A Boolean value indicating whether the pager should
    ///   loop from the last item back to the first.
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

    public var body: some View {
        VStack {
            Group(subviews: content) { subviews in
                subviews[internalIndex]
                    .id(internalIndex)
                    .transition(transition)
                    .onAppear { numberOfSubviews = subviews.count }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            indicator
        }
        .sensoryFeedback(trigger: internalIndex) { _, _ in
            isInitialPageSet ? feedback : nil
        }
        .task {
            await setupInitialPage()
        }
        .onChange(of: externalIndex) { oldIndex, newIndex in
            updateIndex(oldIndex: oldIndex, newIndex: newIndex)
        }
    }

    private var indicator: some View {
        let indicator = PageViewIndicator(
            subviewCount: numberOfSubviews,
            externalIndex: $externalIndex,
            internalIndex: internalIndex,
            configuration: indicatorConfiguration)

        return Group {
            if let proxy = indicatorProxy {
                proxy(indicator)
            } else if isShowingIndicator {
                indicator
            }
        }
        .padding(.bottom, indicatorOffset)
    }

    private func updateIndex(oldIndex: Int, newIndex: Int) {
        guard !isIgnoringChange else {
            isIgnoringChange = false
            return
        }

        let maxIndex = numberOfSubviews - 1
        let adjustedIndex = adjustIndex(newIndex, maxIndex: maxIndex)
        let direction = determineDirection(from: oldIndex, to: adjustedIndex, maxIndex: maxIndex)

        isMovingForward = direction.isForward
        isIgnoringChange = direction.shouldIgnoreChange

        withAnimation(animation) {
            internalIndex = adjustedIndex
            externalIndex = adjustedIndex
        }
    }

    private func adjustIndex(_ index: Int, maxIndex: Int) -> Int {
        guard isLooping else {
            return min(max(index, 0), maxIndex)
        }

        if index < 0 { return maxIndex }
        if index > maxIndex { return 0 }
        return index
    }

    private func determineDirection(
        from oldIndex: Int,
        to newIndex: Int,
        maxIndex: Int
    ) -> (isForward: Bool, shouldIgnoreChange: Bool) {
        guard isLooping else {
            return (newIndex > oldIndex, false)
        }

        if oldIndex == maxIndex, newIndex == 0 {
            return (true, true)
        }

        if oldIndex == 0, newIndex == maxIndex {
            return (false, true)
        }

        return (newIndex > oldIndex, false)
    }

    private func setupInitialPage() async {
        isIgnoringChange = true

        let maxIndex = numberOfSubviews - 1
        let targetIndex = determineInitialIndex()
        let adjustedIndex = adjustIndex(targetIndex, maxIndex: maxIndex)

        internalIndex = adjustedIndex
        externalIndex = adjustedIndex

        isIgnoringChange = false
        try? await Task.sleep(for: .seconds(0.25))
        isInitialPageSet = true
    }

    private func determineInitialIndex() -> Int {
        if externalIndex != 0 {
            return externalIndex
        }

        return switch defaultPage {
        case .first: 0
        case .last: numberOfSubviews - 1
        case .none: 0
        }
    }
}

public extension PageView {
    /// Sets custom transitions for page changes and an optional animation.
    /// - Parameters:
    ///   - forward: The transition to use when moving to the next page.
    ///   - backward: The transition to use when moving to the previous page.
    ///   - animation: An optional animation to apply to the page transitions.
    /// - Returns: A modified instance of `PageView` with the specified transitions and animation.
    func pageTransition(forward: AnyTransition, backward: AnyTransition, animation: Animation? = .default) -> Self {
        var copy = self
        copy.forwardTransition = forward
        copy.backwardTransition = backward
        copy.animation = animation
        return copy
    }

    /// Sets a single transition for both forward and backward page changes and an optional animation.
    /// - Parameters:
    ///   - transition: The transition to use for both forward and backward page changes.
    ///   If `nil`, the default transition is used.
    ///   - animation: An optional animation to apply to the page transition.
    /// - Returns: A modified instance of `PageView` with the specified transition and animation.
    func pageTransition(_ transition: AnyTransition? = nil, animation: Animation? = .default) -> Self {
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
    /// - Returns: A modified instance of `PageView` with the default page set.
    func defaultPage(_ page: Page) -> Self {
        var copy = self
        copy.defaultPage = page
        return copy
    }

    /// Configures a long press action for the page view indicator.
    /// - Parameter action: A closure to be executed when the page view indicator is long-pressed.
    /// - Returns: A modified instance of `PageView` with the specified long press action.
    func pageViewIndicatorLongPressAction(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.indicatorConfiguration.longPressAction = action
        return copy
    }

    /// Configures a tap action for the page view indicator.
    /// - Parameter action: A closure to be executed when the page view indicator is tapped.
    /// - Returns: A modified instance with the specified tap action.
    func pageViewIndicatorTapAction(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.indicatorConfiguration.tapAction = action
        return copy
    }

    /// Sets the haptic feedback for page transitions in the page view.
    /// - Parameter feedback: The haptic feedback to play when the current page changes.
    /// Set to `nil` to disable feedback.
    /// - Returns: A modified instance of `PageView` with the specified feedback configuration.
    func pageViewFeedback(_ feedback: SensoryFeedback?) -> Self {
        var copy = self
        copy.feedback = feedback
        return copy
    }

    /// Configures the page view indicator's visibility.
    /// - Parameter visibility: Determines whether the indicator is visible.
    /// - Returns: A modified instance of `PageView` with the specified indicator visibility.
    func pageViewIndicatorVisibility(_ visibility: Visibility) -> Self {
        var copy = self
        copy.isShowingIndicator = visibility == .visible
        return copy
    }

    /// Configures drag navigation for the page view indicator.
    /// - Parameter navigation: A value that determines whether drag navigation is enabled or disabled.
    /// - Returns: A modified instance of `PageView` with the specified drag navigation configuration.
    func pageViewIndicatorDragNavigation(_ draggability: PageViewIndicatorDraggability) -> Self {
        var copy = self
        copy.indicatorConfiguration.draggability = draggability
        return copy
    }

    /// Sets the visual style of the page view indicator.
    /// - Parameter style: The style to apply to the page view indicator.
    /// - Returns: A modified instance of `PageView` with the specified indicator style.
    func pageViewIndicatorStyle(_ style: PageViewIndicatorStyle) -> Self {
        var copy = self
        copy.indicatorConfiguration.style = style
        return copy
    }

    /// Configures the page view indicator's symbol, size, and spacing.
    /// - Parameters:
    ///   - symbol: The SF Symbol name to use for page indicators. Default is "circle.fill".
    ///   - size: The size of the page indicator symbols. Default is `.regular`.
    ///   - spacing: The spacing between page indicator symbols. Default is `.automatic`.
    /// - Returns: A modified instance of `PageView` with the specified indicator symbol, size, and spacing.
    func pageViewIndicatorIndexSymbol(
        _ symbol: String = "circle.fill",
        size: PageViewIndexSize = .regular,
        spacing: PageViewIndicatorSymbolSpacing = .automatic
    ) -> Self {
        var copy = self
        copy.indicatorConfiguration.indexSymbol = symbol
        copy.indicatorConfiguration.indexSize = size
        copy.indicatorConfiguration.indexSpacing = spacing
        return copy
    }

    /// Sets a custom background style for the page view indicator.
    /// - Parameter background: A shape style to be used as the background for the indicator.
    ///   If `nil`, the background will be removed.
    /// - Returns: A modified instance of PageView with the specified indicator background style.
    public func pageViewIndicatorBackgroundStyle<S: ShapeStyle>(_ style: S) -> Self {
        var copy = self
        copy.indicatorConfiguration.backgroundStyle = AnyShapeStyle(style)
        return copy
    }

    /// Sets a custom background style for the page view indicator.
    /// - Parameter style: Pass `nil` to this parameter to remove the background.
    /// - Returns: A modified instance of PageView with a clear indicator background.
    public func pageViewIndicatorBackgroundStyle(_ style: ExpressibleByNilLiteral?) -> Self {
        var copy = self
        copy.indicatorConfiguration.backgroundStyle = AnyShapeStyle(.clear)
        return copy
    }

    /// Sets the vertical offset of the page view indicator from the bottom of the view.
    /// - Parameter offset: The distance in points to offset the indicator from the bottom.
    /// - Returns: A modified instance of `PageView` with the specified indicator offset.
    func pageViewIndicatorOffset(_ offset: CGFloat) -> Self {
        var copy = self
        copy.indicatorOffset = offset
        return copy
    }
}
