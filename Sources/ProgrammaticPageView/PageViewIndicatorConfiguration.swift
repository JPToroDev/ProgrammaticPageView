//
// PageViewIndicatorConfiguration.swift
// ProgrammaticPageView
// https://github.com/JPToroDev/ProgrammaticPageView
// See LICENSE for license information.
// © 2024 J.P. Toro
//

import SwiftUI

struct PageViewIndicatorConfiguration {
    /// Determines the visual appearance of the page indicator (dots or progress bar).
    var style: PageViewIndicatorStyle = .dotIndicator

    /// The background style for the page view indicator.
    var backgroundStyle: AnyShapeStyle = AnyShapeStyle(.thinMaterial)

    /// A Boolean value that determines whether dragging on the indicator changes the current page.
    var draggability: PageViewIndicatorDraggability = .disabled

    /// The SF Symbol name to use for indicator's indices.
    var indexSymbol: String = "circle.fill"

    /// The spacing between page indicator symbols.
    var indexSpacing: PageViewIndicatorSymbolSpacing = .automatic

    /// The size of the indicator's indices.
    var indexSize: PageViewIndexSize = .regular

    /// An action to perform when the indicator is tapped.
    var tapAction: (() -> Void)?

    /// An action to perform when the indicator is long-pressed.
    var longPressAction: (() -> Void)?
}
