//
//  IndicatorSize.swift
//  ProgrammaticPageView
//
//  Created by JP Toro on 10/7/24.
//

import Foundation

/// Defines the size options for page view indicators.
///
/// Use these cases to specify the size of the indicators in a `PageView`.
/// Each case corresponds to a specific font size used for the indicator.
public enum PageViewIndicatorSize {
    /// A small-sized indicator, with a font size of 6 points.
    case small
    
    /// A regular-sized indicator, with a font size of 8 points.
    case regular
    
    /// A large-sized indicator, with a font size of 10 points.
    case large
    
    /// A custom-sized indicator, allowing you to specify any font size.
    case custom(size: CGFloat)
    
    /// The font size in points for the indicator.
    var pointSize: CGFloat {
        switch self {
        case .small: return 6
        case .regular: return 8
        case .large: return 10
        case .custom(size: let size): return size
        }
    }
}
