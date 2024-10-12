//
//  PageViewIndicatorStyle.swift
//  ProgrammaticPageView
//
//  Created by JP Toro on 10/10/24.
//

import Foundation

/// Defines the visual style options for the page view indicator.
public enum PageViewIndicatorStyle {
    /// Displays the page indicator as a series of dots.
    case dotIndicator
    
    /// Displays the page indicator as a progress bar.
    /// - Parameter width: The width of the progress bar.
    case progressBar(width: CGFloat)
    
    /// Creates a progress bar style with the default width of 100 points.
    public static var progressBar: PageViewIndicatorStyle {
        return .progressBar(width: 100)
    }
}
