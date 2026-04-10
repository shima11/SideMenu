# SideMenu

A highly customizable, gesture-driven side menu component for SwiftUI with full accessibility support.

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-6.0+-orange.svg" alt="Swift 6.0+">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License">
</p>

## Features

- **Fluid Gesture** - Velocity-based spring animations with rubber band effect at menu edges
- **3 Presentation Styles** - Slide-in-over, slide-in-out, and slide-out (Threads-like) + custom layout
- **Gesture Control** - Full-screen or edge-only drag activation with configurable sensitivity
- **Haptic Feedback** - Configurable haptic feedback on open/close and rubber band limit
- **Visual Effects** - Per-style blur, scale, and dim effects for natural transitions
- **Accessibility** - Complete VoiceOver support with focus management and escape actions
- **Type Safe** - Fully documented public API with Swift 6 concurrency support

## Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add SideMenu to your project via Xcode:

1. File > Add Package Dependencies...
2. Enter the repository URL: `https://github.com/shima11/SideMenu`
3. Select the version you want to use

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/shima11/SideMenu", from: "0.1.0")
]
```

## Quick Start

```swift
import SwiftUI
import SideMenu

struct ContentView: View {
    @State private var menuState = SideMenuState()

    var body: some View {
        SideMenuView(model: menuState) {
            // Side menu content
            List {
                Button("Home") { withAnimation { menuState.close() } }
                Button("Settings") { withAnimation { menuState.close() } }
            }
        } mainView: {
            NavigationStack {
                Text("Main Content")
                    .navigationTitle("Home")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Menu", systemImage: "line.3.horizontal") {
                                withAnimation { menuState.toggle() }
                            }
                        }
                    }
            }
        }
    }
}
```

For a complete interactive example with all configuration options, check out the `Demo` app in the repository.

## Menu Styles

### slideInOver

Menu slides over the main content, which remains in place.

```swift
SideMenuConfiguration(
    menuStyle: .slideInOver(blur: 3, scale: 0.95, dimValue: 0.3)
)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `blur` | `2` | Blur radius applied to main content |
| `scale` | `1` | Scale factor applied to main content |
| `dimValue` | `0.2` | Dim overlay opacity |

### slideInOut

Menu and main content slide together.

```swift
SideMenuConfiguration(
    menuStyle: .slideInOut(dimValue: 0.2)
)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `dimValue` | `0.2` | Dim overlay opacity |

### slideOut

Main content slides out to reveal the menu underneath (like Meta Threads).

```swift
SideMenuConfiguration(
    menuStyle: .slideOut(scale: 0.9, dimValue: 0.2, backgroundColor: .systemBackground)
)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `scale` | `0.9` | Scale factor for the menu |
| `dimValue` | `0.2` | Dim overlay opacity |
| `backgroundColor` | `nil` | Background color behind the menu during scale animation |

### custom

Fully custom layout with user-defined closures.

```swift
SideMenuConfiguration(
    menuStyle: .custom(
        dimValue: 0.2,
        sideMenuLayout: { context, menuView in
            // Custom menu layout
        },
        mainViewLayout: { context, mainView in
            // Custom main view layout
        }
    )
)
```

## Configuration

### SideMenuConfiguration

```swift
let config = SideMenuConfiguration(
    menuWidth: 0.7,
    menuStyle: .slideInOver(blur: 3, scale: 0.95, dimValue: 0.3),
    menuAnimation: .spring(duration: 0.4, bounce: 0.2),
    dragActivation: .edge(edgeWidth: 30),
    hapticStyle: .medium
)

SideMenuView(model: menuState, configuration: config) {
    MenuView()
} mainView: {
    MainContentView()
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `menuWidth` | `CGFloat` | `0.8` | Width of menu as fraction of screen (0.0 to 1.0) |
| `menuStyle` | `MenuStyle` | `.slideInOut()` | Presentation style |
| `menuAnimation` | `Animation` | `.spring(duration: 0.4, bounce: 0.0)` | Animation curve for transitions |
| `dragActivation` | `MenuDragActivation` | `.full()` | Drag activation area |
| `hapticStyle` | `FeedbackStyle?` | `.medium` | Haptic feedback style (`nil` to disable) |
| `edge` | `MenuEdge` | `.leading` | Which screen edge the menu appears from |
| `velocityThreshold` | `CGFloat` | `300` | Minimum flick velocity (pt/s) to trigger open/close |
| `rubberBandLimit` | `CGFloat` | `40` | Maximum rubber band displacement in points |

### Drag Activation

Control how users can open the menu with gestures.

```swift
// Full-screen drag (default)
.full(startThreshold: 15, openCloseThreshold: 50, directionRatio: 1.5)

// Edge-only drag
.edge(edgeWidth: 24, startThreshold: 15, openCloseThreshold: 50, directionRatio: 1.5)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `edgeWidth` | `24` | Width of edge drag area in points (edge only) |
| `startThreshold` | `15` | Minimum horizontal drag distance to start gesture |
| `openCloseThreshold` | `50` | Minimum drag distance to open/close |
| `directionRatio` | `1.5` | Required horizontal/vertical ratio (higher = stricter) |

### Programmatic Control

```swift
// Open the menu
withAnimation { menuState.open() }

// Close the menu
withAnimation { menuState.close() }

// Toggle the menu
withAnimation { menuState.toggle() }

// Check if menu is open
if menuState.isOpen { /* ... */ }
```

## Accessibility

SideMenu includes comprehensive accessibility support:

- **VoiceOver** - Proper focus management between menu and main content
- **Escape Action** - VoiceOver users can close the menu with escape gesture
- **Modal Trait** - Menu is announced as modal when open
- **Focus Management** - Automatic focus transfer when menu opens/closes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

Implementation inspired by this [Medium article](https://medium.com/better-programming/sidemenu-using-swiftui-939a01c86ecd).
