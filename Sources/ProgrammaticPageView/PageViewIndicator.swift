//
//  PageViewIndicator.swift
//  ProgrammaticPageView
//
//  Created by Joshua Toro on 10/7/24.
//

import SwiftUI

/// Displays a customizable page indicator for multi-page views.
struct PageViewIndicator: View {
    /// The total number of pages to represent.
    var subviewCount: Int
    
    /// A binding to the current page index.
    @Binding var currentIndex: Int
    
    /// A Boolean value that determines whether tapping on indicators changes the current page.
    ///
    /// When `true`, tapping an indicator will update `currentIndex`.
    var isInteractionEnabled: Bool
    
    /// The SF Symbol name to use for page indicators.
    var pageSymbol: String
    
    /// The spacing between page indicator symbols.
    var symbolSpacing: PageViewIndicatorSymbolSpacing
    
    /// The size of the page indicators.
    ///
    /// This property determines the font size of the SF Symbols used for the page indicators.
    var indicatorSize: PageViewIndicatorSize
    
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
        HStack(spacing: symbolSpacing.size) {
            ForEach(0..<subviewCount, id: \.self) { index in
                Image(systemName: pageSymbol)
                    .font(.system(size: indicatorSize.pointSize))
                    .foregroundStyle(currentIndex == index ? .white : Color(.tertiaryLabel))
                    .symbolEffect(.bounce.up, options: .nonRepeating, isActive: currentIndex == index)
                    .animation(nil, value: longPressPhase)
                    .if(isInteractionEnabled) { content in
                      content
                        .onTapGesture {
                          currentIndex = index
                        }
                    }
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
        .if(isInteractionEnabled) { content in
          content
            .onLongPressGesture(minimumDuration: 0.5) {
                longPressPhase = .pressed
                indicatorLongPressAction?()
            } onPressingChanged: { isInProgress in
                longPressPhase = isInProgress ? .pressing : .inactive
            }
        }
    }
}
