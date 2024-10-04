//
//  PageViewIndicatorSymbolSpacing.swift
//  ProgrammaticPageView
//
//  Created by Joshua Toro on 10/8/24.
//

import Foundation

/// Represents predefined and custom spacing options for page view indicator symbols.
public enum PageViewIndicatorSymbolSpacing {
    /// The default spacing between symbols.
    case `default`
    /// Narrow spacing between symbols.
    case narrow
    /// Wide spacing between symbols.
    case wide
    /// Custom spacing between symbols, specified in points.
    case custom(size: CGFloat)
    
    /// The spacing size in points.
    var size: CGFloat {
        switch self {
        case .default: return 8
        case .narrow: return 6
        case .wide: return 10
        case .custom(size: let size): return size
        }
    }
}
