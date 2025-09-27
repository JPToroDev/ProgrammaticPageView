<div align="center">
  <img src="https://github.com/user-attachments/assets/cf070302-3a47-4619-a90a-bb06bd1ed305" height="500">
</div>

<div align="center">

# ProgrammaticPageView 📱✨

A SwiftUI pager view for programmatic navigation with customizable transitions. Ideal for onboarding screens and multi-step forms requiring fine-grained control.

[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%2018%2B%20%7C%20macOS%2015%2B-lightgrey.svg)](https://developer.apple.com/)

</div>

## Features 🌟

- 🎛️ Programmatic navigation via index binding
- 🔄 Customizable forward/backward transitions
- 🔁 Optional looping
- 🧩 Dynamic content handling
- 🔒 Fine-grained navigation control
- 🎨 Customizable indicator styling and gestures

## Why ProgrammaticPageView? 🤔

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

## Installation 📦

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/JPToroDev/ProgrammaticPageView.git", from: "1.0.0")
]
```

Or add it via Xcode by going to File > Add Packages… and entering the repository URL.

## Example 💡

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
                    .buttonStyle(.borderedProminent)
            }

            List {
                Text("Please accept terms and conditions.")
                Toggle("Accept Terms", isOn: $hasAcceptedTerms)

                Section {
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
        .pageViewIndicatorVisibility(.visible)
        .pageViewIndicatorIndexSymbol("square.fill", size: .large)
        .pageViewIndicatorStyle(.progressBar)
        .pageViewIndicatorBackgroundStyle(.blue)
        .pageViewIndicatorOffset(20)
    }
}
```

## API Reference 📚

### Initializers

```swift
public init(
    index: Binding<Int>,
    loops: Bool = false,
    @ViewBuilder content: () -> Content
)

public init(
    index: Binding<Int>,
    loops: Bool = false,
    @ViewBuilder content: () -> Content,
    @ViewBuilder indicator: @escaping (PageViewIndicator) -> Indicator
)
```

- `index`: A binding to the current page index.
- `loops`: Set to `true` to enable looping from the last page to the first.
- `content`: A view builder that returns the views for each page.
- `indicator`: A view builder that takes a `PageViewIndicator` and returns a custom indicator view. Use this to directly modify or replace the default indicator.

The first initializer creates a `PageView` with default indicator behavior controlled by `pageViewIndicatorVisibility()`.
The second initializer allows for a custom indicator view to be provided.

### Methods

#### Page Transitions

```swift
pageTransition(forward: AnyTransition, backward: AnyTransition, animation: Animation? = .default) -> Self
```

Sets custom transitions for page changes and an optional animation.
- `forward`: The transition to use when moving to the next page.
- `backward`: The transition to use when moving to the previous page.
- `animation`: An optional animation to apply to the page transitions.

```swift
pageTransition(_ transition: AnyTransition? = nil, animation: Animation? = .default) -> Self
```

Sets a single transition for both forward and backward page changes and an optional animation.
- `transition`: The transition to use for both forward and backward page changes. If `nil`, the default transition is used.
- `animation`: An optional animation to apply to the page transition.

#### Page Configuration

```swift
defaultPage(_ page: Page) -> Self
```

Sets the default page without animation. This will be overridden if `index` is not zero.
- `page`: `.first` or `.last`.

```swift
pageViewFeedback(_ feedback: SensoryFeedback?) -> Self
```

Sets the haptic feedback for page transitions in the page view.
- `feedback`: The haptic feedback to play when the current page changes. Set to `nil` to disable feedback.

#### Indicator Configuration

```swift
pageViewIndicatorVisibility(_ visibility: Visibility) -> Self
```

Configures the page view indicator's visibility.
- `visibility`: Determines whether the indicator is visible.

```swift
pageViewIndicatorStyle(_ style: PageViewIndicatorStyle) -> Self
```

Sets the visual style of the page view indicator.
- `style`: The style to apply to the page view indicator.

```swift
pageViewIndicatorDragNavigation(_ draggability: PageViewIndicatorDraggability) -> Self
```

Configures drag navigation for the page view indicator.
- `draggability`: A value that determines whether drag navigation is enabled or disabled.

#### Indicator Styling

```swift
pageViewIndicatorIndexSymbol(_ symbol: String = "circle.fill", size: PageViewIndexSize = .regular, spacing: PageViewIndicatorSymbolSpacing = .automatic) -> Self
```

Configures the page view indicator's symbol, size, and spacing.
- `symbol`: The SF Symbol name to use for page indicators. Default is "circle.fill".
- `size`: The size of the page indicator symbols. Default is `.regular`.
- `spacing`: The spacing between page indicator symbols. Default is `.automatic`.

```swift
pageViewIndicatorBackgroundStyle<S: ShapeStyle>(_ style: S) -> Self
```

Sets a custom background style for the page view indicator.
- `style`: A shape style to be used as the background for the indicator.

```swift
pageViewIndicatorBackgroundStyle(_ style: ExpressibleByNilLiteral?) -> Self
```

Removes the background style from the page view indicator.
- `style`: Pass `nil` to remove the background.

```swift
pageViewIndicatorOffset(_ offset: CGFloat) -> Self
```

Sets the vertical offset of the page view indicator from the bottom of the view.
- `offset`: The distance in points to offset the indicator from the bottom.

#### Indicator Actions

```swift
pageViewIndicatorTapAction(_ action: @escaping () -> Void) -> Self
```

Configures a tap action for the page view indicator.
- `action`: A closure to be executed when the page view indicator is tapped.

```swift
pageViewIndicatorLongPressAction(_ action: @escaping () -> Void) -> Self
```

Configures a long press action for the page view indicator.
- `action`: A closure to be executed when the page view indicator is long-pressed.

## License

This project is licensed under the MIT License.

## Contributing 🤝

Contributions are welcome! Please open an issue or submit a pull request.

## Contact 📧

For questions or suggestions, please open an issue on GitHub.
