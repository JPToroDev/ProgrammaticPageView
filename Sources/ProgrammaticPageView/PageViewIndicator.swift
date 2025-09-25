//
// PageViewIndicator.swift
// ProgrammaticPageView
// https://github.com/JPToroDev/ProgrammaticPageView
// See LICENSE for license information.
// © 2024 J.P. Toro
//

import SwiftUI

/// Displays a customizable page indicator for multi-page views.
public struct PageViewIndicator: View {
    /// The total number of pages to represent.
    var subviewCount: Int

    /// A binding to the currently selected page index,
    /// allowing two-way communication with parent views.
    @Binding var externalIndex: Int

    /// The current page index used for internal calculations and animations.
    var internalIndex: Int

    var configuration: PageViewIndicatorConfiguration

    private enum LongPressPhase {
        case inactive, pressing, pressed

        var scale: Double {
            switch self {
            case .inactive: return 1
            case .pressing: return 1.05
            case .pressed: return 1.2
            }
        }

        var speed: Double {
            switch self {
            case .pressing: return 0.2
            default: return 1
            }
        }
    }

    @State private var dragLocation: CGPoint = .zero
    @State private var indicatorSize: CGSize = .zero
    @State private var indicatorTapped: Bool = false
    @State private var feedback: SensoryFeedback?

    @State private var longPressPhase: LongPressPhase = .inactive
    @GestureState private var isDetectingLongPress = false
    @State private var isLongPressComplete = false

    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                feedback = .impact
                configuration.tapAction?()
                let animation: Animation = .spring.speed(3)
                withAnimation(animation) {
                    indicatorTapped = true
                } completion: {
                    withAnimation(animation) {
                        feedback = nil
                        indicatorTapped = false
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                handleDrag(value)
            }
            .onEnded { value in
                handleDragEnd(value)
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 1)
            .updating($isDetectingLongPress) { currentState, gestureState, _ in
                // Do not try to alter state from within these closures!
                gestureState = currentState
            }
            .onEnded { isFinished in
                isLongPressComplete = isFinished
            }
    }

    public var body: some View {
        Group {
            if case .progressBar(let width) = configuration.style {
                progressBar(width: width)
            } else {
                dotIndicator
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(indicatorBackground)
        .onChange(of: isLongPressComplete) {
            guard isLongPressComplete else { return }
            Task { await completeLongPress() }
        }
        .onChange(of: isDetectingLongPress, handleLongPress)
        .scaleEffect(longPressPhase.scale)
        .scaleEffect(indicatorTapped ? 1.075 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.6).speed(longPressPhase.speed), value: longPressPhase)
        .gesture(longPressGesture, isEnabled: configuration.longPressAction != nil)
        .gesture(dragGesture, isEnabled: configuration.draggability == .enabled)
        .gesture(tapGesture, isEnabled: configuration.tapAction != nil)
        .sensoryFeedback(trigger: feedback) { _, feedback in
            feedback
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            indicatorSize = size
        }
    }

    private var indicatorBackground: some View {
        Capsule()
            .fill(configuration.backgroundStyle)
            .overlay(
                Capsule()
                    .fill(.primary)
                    .opacity(longPressPhase != .inactive || indicatorTapped ? 0.05 : 0)
            )
    }

    private var dotIndicator: some View {
        HStack(spacing: configuration.indexSpacing.size) {
            ForEach(0 ..< subviewCount, id: \.self) { index in
                Image(systemName: configuration.indexSymbol)
                    .font(.system(size: configuration.indexSize.pointSize))
                    .foregroundStyle(externalIndex == index ? .white : Color(.tertiaryLabel))
                    .symbolEffect(.bounce.up, options: .nonRepeating, isActive: externalIndex == index)
                    .animation(nil, value: longPressPhase)
            }
        }
    }

    private func handleLongPress() {
        if isDetectingLongPress {
            longPressPhase = .pressing
        } else if !isLongPressComplete {
            longPressPhase = .inactive
        }
    }

    private func completeLongPress() async {
        longPressPhase = .pressed
        feedback = .success
        configuration.longPressAction?()
        try? await Task.sleep(for: .seconds(0.5))
        longPressPhase = .inactive
        feedback = nil
        isLongPressComplete = false
    }

    private func progressBar(width: CGFloat) -> some View {
        PageViewProgressBar(currentIndex: internalIndex, pageCount: subviewCount)
            .frame(maxWidth: width)
    }

    private func handleDrag(_ value: DragGesture.Value) {
        dragLocation = value.location

        if case .progressBar = configuration.style {
            handleProgressBarDrag(value)
        } else {
            updateIndexBasedOnDrag()
        }
    }

    private func handleProgressBarDrag(_ value: DragGesture.Value) {
        let adjustedX = value.location.x
        let clampedX = max(0, min(adjustedX, indicatorSize.width))
        let proportion = clampedX / indicatorSize.width
        let calculatedIndex = min(Int(proportion * CGFloat(subviewCount)), subviewCount - 1)
        let newIndex = calculatedIndex

        if newIndex != externalIndex {
            externalIndex = newIndex
        }
    }

    private func handleDragEnd(_ value: DragGesture.Value) {
        dragLocation = .zero
    }

    private func updateIndexBasedOnDrag() {
        guard indicatorSize.width > 0, subviewCount > 0 else { return }

        // Make sure drag position doesn't go outside the indicator
        let adjustedX = max(0, min(dragLocation.x, indicatorSize.width))

        // Ignore the padding around each dot
        let horizontalPadding = 16.0
        let contentWidth = indicatorSize.width - (2 * horizontalPadding)
        let contentStartX = horizontalPadding

        // Convert our drag position to where it is within just the dots area
        let relativeX = adjustedX - contentStartX

        // Wait until they're dragging over the actual dots
        guard relativeX >= 0, relativeX <= contentWidth else { return }

        // Split the dots area into equal chunks -- one chunk per dot
        let zoneWidth = contentWidth / CGFloat(subviewCount)
        let index = Int(relativeX / zoneWidth)

        externalIndex = min(max(index, 0), subviewCount - 1)
    }
}
