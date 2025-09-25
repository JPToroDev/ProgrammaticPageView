//
// PageViewIndexSize.swift
// ProgrammaticPageView
// https://github.com/JPToroDev/ProgrammaticPageView
// See LICENSE for license information.
// © 2024 J.P. Toro
//

import Foundation

/// Defines the size options for page view indicators.
///
/// Use these cases to specify the size of the indicator's indices in a `PageView`.
/// Each case corresponds to a specific font size used for the indices.
public enum PageViewIndexSize {
    /// A small-sized index, with a font size of 6 points.
    case small

    /// A regular-sized index, with a font size of 8 points.
    case regular

    /// A large-sized index, with a font size of 10 points.
    case large

    /// A custom-sized index, allowing you to specify any font size.
    case custom(size: CGFloat)

    /// The font size in points for an index.
    var pointSize: CGFloat {
        switch self {
        case .small: return 6
        case .regular: return 8
        case .large: return 10
        case .custom(size: let size): return size
        }
    }
}
