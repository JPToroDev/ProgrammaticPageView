//
// PageViewIndicatorSymbolSpacing.swift
// ProgrammaticPageView
// https://github.com/JPToroDev/ProgrammaticPageView
// See LICENSE for license information.
// © 2024 J.P. Toro
//

import Foundation

/// Represents predefined and custom spacing options for page view indicator symbols.
public enum PageViewIndicatorSymbolSpacing {
    /// The default spacing between symbols.
    case automatic

    /// Narrow spacing between symbols.
    case narrow

    /// Wide spacing between symbols.
    case wide

    /// Custom spacing between symbols, specified in points.
    case custom(CGFloat)

    /// The spacing size in points.
    var size: CGFloat {
        switch self {
        case .automatic: return 8
        case .narrow: return 6
        case .wide: return 10
        case .custom(size: let size): return size
        }
    }
}
