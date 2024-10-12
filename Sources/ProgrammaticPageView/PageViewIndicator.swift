//
//  PageViewIndicator.swift
//  ProgrammaticPageView
//
//  Created by JP Toro on 10/7/24.
//

import SwiftUI

/// Displays a customizable page indicator for multi-page views.
struct PageViewIndicator: View {
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
    
    var indicatorLongPressAction: (() -> Void)?
    
    private enum LongPressPhase {
        case inactive, pressing, pressed
    }
    
    @State private var longPressPhase: LongPressPhase = .inactive
    
    private var maxScale: CGFloat {
        switch longPressPhase {
        case .inactive: return 1
        case .pressing: return 1.05
        case .pressed:  return 1.2
        }
    }
    
    private var animationSpeed: Double {
        switch longPressPhase {
        case .inactive: return 1
        case .pressing: return 0.2
        case .pressed:  return 1
        }
    }
    
    var body: some View {
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
                .colorMultiply(longPressPhase != .inactive ? Color.gray.mix(with: .white, by: 0.8) : .white)
        }
        .scaleEffect(maxScale)
        .animation(.spring(response: 0.4, dampingFraction: 0.6).speed(animationSpeed), value: longPressPhase)
        .sensoryFeedback(trigger: longPressPhase) { _, phase in
            phase == .pressed ? .success : .none
        }
        .if(indicatorLongPressAction != nil) { content in
            content
                .onLongPressGesture(minimumDuration: 0.5) {
                    longPressPhase = .pressed
                    indicatorLongPressAction?()
                } onPressingChanged: { isInProgress in
                    longPressPhase = isInProgress ? .pressing : .inactive
                }
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
                    .if(areIndicesInteractive) { content in
                        content
                            .onTapGesture {
                                externalIndex = index
                            }
                    }
            }
        }
    }
    
    private func progressBar(width: CGFloat) -> some View {
        PageViewProgressBar(currentIndex: internalIndex, pageCount: subviewCount)
            .frame(maxWidth: width)
    }
}

