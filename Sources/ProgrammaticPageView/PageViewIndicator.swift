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
    
    var body: some View {
        HStack(spacing: symbolSpacing.size) {
            ForEach(0..<subviewCount, id: \.self) { index in
                Image(systemName: pageSymbol)
                    .font(.system(size: indicatorSize.pointSize))
                    .foregroundStyle(currentIndex == index ? .white : Color(.tertiaryLabel))
                    .symbolEffect(.bounce.up, options: .nonRepeating, isActive: currentIndex == index)
                    .onTapGesture {
                        if isInteractionEnabled {
                            currentIndex = index
                        }
                    }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            indicatorBackgroundStyle.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.clear),
            in: .capsule)
    }
}
