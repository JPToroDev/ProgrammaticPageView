//
//  PageViewIndicator.swift
//  ProgrammaticPageView
//
//  Created by JP Toro on 10/7/24.
//

import SwiftUI

/// Displays a customizable page indicator for multi-page views.
public struct PageViewIndicator: View {
    /// The total number of pages to represent.
    var subviewCount: Int
    
    /// A binding to the currently selected page index, allowing two-way communication with parent views.
    @Binding var externalIndex: Int
    
    /// The current page index used for internal calculations and animations.
    var internalIndex: Int
    
    /// Determines the visual appearance of the page indicator (dots or progress bar).
    var style: PageViewIndicatorStyle
    
    /// A Boolean value that determines whether tapping on index icons changes the current page.
    ///
    /// When `true`, tapping an index icon will update `currentIndex`.
    var areIndicesInteractive: Bool
    
    /// The SF Symbol name to use for indicator's indices.
    var indexSymbol: String
    
    /// The spacing between page indicator symbols.
    var symbolSpacing: PageViewIndicatorSymbolSpacing
    
    /// The size of the page indicators.
    ///
    /// This property determines the font size of the SF Symbols used for the page indicators.
    var symbolSize: PageViewIndicatorSize
    
    /// The background style for the page view indicator.
    var indicatorBackgroundStyle: AnyShapeStyle?
    
    /// An action to perform when the indicator is tapped.
    var indicatorTapAction: (() -> Void)?
    
    /// An action to perform when the indicator is long-pressed.
    var indicatorLongPressAction: (() -> Void)?
    
    private enum LongPressPhase {
        case inactive, pressing, pressed
    }
    
    @State private var dragLocation: CGPoint = .zero
    @State private var indicatorSize: CGSize = .zero
    @State private var longPressPhase: LongPressPhase = .inactive
    @State private var indicatorTapped: Bool = false
    @State private var feedback: SensoryFeedback?
    
    private var longPressScale: CGFloat {
        switch longPressPhase {
        case .inactive: return 1
        case .pressing: return 1.05
        case .pressed:  return 1.2
        }
    }
    
    private var longPressSpeed: Double {
        switch longPressPhase {
        case .pressing: return 0.2
        default: return 1
        }
    }
    
    public var body: some View {
        
        let tapGesture = TapGesture()
            .onEnded { _ in
                feedback = .impact
                indicatorTapAction?()
                let animation: Animation = .spring.speed(3)
                withAnimation(animation) { indicatorTapped = true } completion: {
                    withAnimation(animation) {
                        feedback = nil
                        indicatorTapped = false
                    }
                }
            }
        
        let dragGesture = DragGesture(minimumDistance: 5)
            .onChanged { value in
                handleDrag(value)
            }
            .onEnded { value in
                handleDragEnd(value)
            }
        
        Group {
            if case .progressBar(let width) = style {
                progressBar(width: width)
            } else {
                dotIndicator
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background {
            Capsule()
                .fill(indicatorBackgroundStyle.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.clear))
                .overlay(
                    Capsule()
                        .fill(Material.thin)
                        .opacity(longPressPhase != .inactive || indicatorTapped ? 1 : 0)
                )
        }
        .scaleEffect(longPressScale)
        .scaleEffect(indicatorTapped ? 1.075 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.6).speed(longPressSpeed), value: longPressPhase)
        .if(indicatorLongPressAction != nil) { content in
            // There is a bug preventing LongPressGesture() from working,
            // so we'll use the gesture's modifier variant conditionally
            content
                .onLongPressGesture(minimumDuration: 0.5) {
                    feedback = .success
                    longPressPhase = .pressed
                    indicatorLongPressAction?()
                } onPressingChanged: { isInProgress in
                    feedback = nil
                    longPressPhase = isInProgress ? .pressing : .inactive
                }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            return proxy.size
        } action: { size in
            indicatorSize = size
        }
        .gesture(dragGesture, isEnabled: areIndicesInteractive)
        .gesture(tapGesture, isEnabled: indicatorTapAction != nil)
        .sensoryFeedback(trigger: feedback) { _, feedback in
            return feedback
        }
    }
    
    private var dotIndicator: some View {
        HStack(spacing: symbolSpacing.size) {
            ForEach(0..<subviewCount, id: \.self) { index in
                Image(systemName: indexSymbol)
                    .font(.system(size: symbolSize.pointSize))
                    .foregroundStyle(externalIndex == index ? .white : Color(.tertiaryLabel))
                    .symbolEffect(.bounce.up, options: .nonRepeating, isActive: externalIndex == index)
                    .animation(nil, value: longPressPhase)
            }
        }
    }
    
    private func progressBar(width: CGFloat) -> some View {
        PageViewProgressBar(currentIndex: internalIndex, pageCount: subviewCount)
            .frame(maxWidth: width)
    }
    
    private func handleDrag(_ value: DragGesture.Value) {
        dragLocation = value.location
        
        if case .progressBar = style {
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
        guard indicatorSize.width > 0 else { return }

        let totalDots = CGFloat(subviewCount)
        let totalSpacing = CGFloat(subviewCount - 1) * symbolSpacing.size
        let combinedWidth = (totalDots * symbolSize.pointSize) + totalSpacing
        let scale = indicatorSize.width / combinedWidth

        let scaledUnitWidth = (symbolSize.pointSize + symbolSpacing.size) * scale
        let adjustedX = max(0, min(dragLocation.x, indicatorSize.width))

        let floatIndex = adjustedX / scaledUnitWidth
        let index = Int(floatIndex.rounded())

        externalIndex = min(max(index, 0), subviewCount - 1)
    }
}

