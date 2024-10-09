# ProgrammaticPageView

A SwiftUI pager view for programmatic navigation with customizable transitions. Ideal for onboarding screens and multi-step forms requiring fine-grained control.

> **Note:** Requires iOS 18 and aligned releases

[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-lightgrey.svg)](https://developer.apple.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

## Features

- 🎛️ Programmatic navigation via index binding
- 🔄 Customizable forward/backward transitions
- 🔁 Optional looping
- 🧩 Dynamic content handling
- 🔒 Fine-grained navigation control
- 🎨 Customizable page indicator

## Why ProgrammaticPageView?

### Limitations of Alternatives

#### `TabView` with `.tabViewStyle(.page)`
- Can't disable drag gesture
- Can't customize page indicator
- Limited transition customization

#### `ScrollView` with `.scrollDisabled(true)`
- Complex navigation logic for conditional views
- Poor interaction with nested vertical scroll views

### Benefits

- 🚀 Simple index-based navigation
- 🔀 Effortless conditional view support
- ✨ Custom SwiftUI transitions and animations
- 📱 Ideal for guided user flows

## Installation

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/JPToroDev/ProgrammaticPageView.git", from: "1.0.0")
]
```

Or add it via Xcode by going to File > Add Packages… and entering the repository URL.

## Example

### Onboarding Flow with Conditional Navigation and Custom Indicator

```swift
import SwiftUI
import ProgrammaticPageView

struct OnboardingView: View {
    @State private var pageIndex = 0
    @State private var hasAcceptedTerms = false
    
    var body: some View {
        PageView(index: $pageIndex) {
            VStack {
                Text("Welcome!")
                Button("Next") { pageIndex += 1 }
            }
            if !hasAcceptedTerms {
                List {
                    Text("Please accept terms and conditions.")
                    Toggle("Accept Terms", isOn: $hasAcceptedTerms)
                    Button("Next") { pageIndex += 1 }
                        .disabled(!hasAcceptedTerms)
                }
            }
            VStack {
                Text("All Set!")
                Button("Get Started") {
                    // Proceed to main app
                }
            }
        }
        .pageViewIndicator(visibility: .visible, interactionEnabled: true)
        .pageViewIndicatorSymbol("square.fill", size: .large)
        .pageViewIndicatorBackground(Color.blue.opacity(0.2))
        .pageViewIndicatorOffset(20)
    }
}
```

## API Reference

### Initializer

```swift
public init(
    index: Binding<Int>,
    loops: Bool = false,
    @ViewBuilder content: () -> Content
)
```

- `index`: A binding to the current page index.
- `loops`: Set to `true` to enable looping from the last page to the first.
- `content`: A closure that returns the views for each page.

### Methods

```swift
pageTransition(forward: AnyTransition, backward: AnyTransition, animation: Animation? = .default) -> Self
```

Sets custom transitions for page changes and an optional animation.
- `forward`: The transition to use when moving to the next page.
- `backward`: The transition to use when moving to the previous page.
- `animation`: An optional animation to apply during page transitions.

```swift
pageTransition(_ transition: AnyTransition? = nil, animation: Animation? = .default) -> Self
```

Sets a single transition for both forward and backward page changes and an optional animation.
- `transition`: The transition to use for both forward and backward page changes. If `nil`, the default transition is used.
- `animation`: An optional animation to apply during page transitions.

```swift
defaultPage(_ page: Page = .first) -> Self
```

Sets the default page without animation. This will be overridden if `index` is not zero.
- `page`: `.first` or `.last`.

```swift
pageViewIndicator(visibility: Visibility = .visible, interactionEnabled: Bool = false) -> Self
```

Configures the page view indicator's visibility and interaction.
- `visibility`: Determines whether the indicator is visible.
- `interactionEnabled`: Determines whether tapping on indicators changes the current page.

```swift
func pageViewFeedback(_ feedback: SensoryFeedback?) -> Self
```

Sets the haptic feedback for page transitions in the page view.
- `feedback`: The haptic feedback to play when the current page changes. Set to `nil` to disable feedback.

```swift
func pageViewIndicatorLongPressAction(_ action: @escaping () -> Void) -> Self
```

Configures a long press action for the page view indicator.
- `action`: A closure to be executed when the page view indicator is long-pressed.

```swift
func pageViewIndicatorSymbol(_ pageSymbol: String = "circle.fill", size: PageViewIndicatorSize = .regular, spacing: PageViewIndicatorSymbolSpacing = .default) -> Self
```
Configures the page view indicator's symbol, size, and spacing.
- `pageSymbol`: The SF Symbol name to use for page indicators. Default is "circle.fill".
- `size`: The size of the page indicator symbols. Default is `.regular`.
- `spacing`: The spacing between page indicator symbols. Default is `.default`.

```swift
pageViewIndicatorBackground<S: ShapeStyle>(_ background: S?) -> Self
```

Sets a custom background style for the page view indicator.
- `background`: A shape style to be used as the background for the indicator. If `nil`, the background will be removed.

```swift
pageViewIndicatorOffset(_ offset: CGFloat) -> Self
```

Sets the vertical offset of the page view indicator from the bottom of the view.
- `offset`: The distance in points to offset the indicator from the bottom.

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Contact

For questions or suggestions, please open an issue on GitHub.
