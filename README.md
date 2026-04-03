# SideMenu

A highly customizable, gesture-driven side menu component for SwiftUI with full accessibility support.

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-6.0+-orange.svg" alt="Swift 6.0+">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License">
</p>

## Features

- ✅ **Smooth Animations** - Customizable animation curves with snappy, spring, and ease-in-out options
- ✅ **Gesture Support** - Full drag gesture support with configurable edge or full-screen activation
- ✅ **Accessibility** - Complete VoiceOver support with proper focus management and escape actions
- ✅ **Haptic Feedback** - Optional haptic feedback for enhanced user experience
- ✅ **Visual Effects** - Configurable blur, scale, and dim effects for the main content
- ✅ **Two Presentation Styles** - Choose between slide-in-over or slide-in-out animations
- ✅ **Highly Configurable** - Extensive customization options for all visual and behavioral aspects
- ✅ **Type Safe** - Fully documented public API with SwiftUI best practices

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
    .package(url: "https://github.com/shima11/SideMenu", from: "1.0.0")
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
            MenuView()
        } mainView: {
            // Main content
            MainContentView(menuState: menuState)
        }
    }
}

struct MenuView: View {
    var body: some View {
        List {
            NavigationLink("Home", destination: Text("Home"))
            NavigationLink("Settings", destination: Text("Settings"))
            NavigationLink("Profile", destination: Text("Profile"))
        }
    }
}

struct MainContentView: View {
    @Bindable var menuState: SideMenuState

    var body: some View {
        NavigationStack {
            Text("Main Content")
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Menu", systemImage: "line.3.horizontal") {
                            withAnimation {
                                menuState.toggle()
                            }
                        }
                    }
                }
        }
    }
}
```

For a complete interactive example with all configuration options, check out the `Demo` app in the repository.

## Advanced Usage

### Custom Configuration

```swift
let config = SideMenuConfiguration(
    menuWidth: 0.7,              // Menu takes 70% of screen width
    menuStyle: .slideInOver,      // Menu slides over content
    blur: 3,                      // Blur radius for main content
    scale: 0.95,                  // Scale main content to 95%
    dimValue: 0.3,                // Dim overlay opacity
    menuAnimation: .spring(duration: 0.4, bounce: 0.2),
    dragActivation: .edge,        // Only edge drags open menu
    dragEdgeWidth: 30,            // Edge width in points
    enableHaptics: true           // Enable haptic feedback
)

SideMenuView(
    model: menuState,
    configuration: config
) {
    MenuView()
} mainView: {
    MainContentView(menuState: menuState)
}
```

### Programmatic Control

```swift
// Open the menu
withAnimation {
    menuState.open()
}

// Close the menu
withAnimation {
    menuState.close()
}

// Toggle the menu
withAnimation {
    menuState.toggle()
}

// Check if menu is open
if menuState.isOpen {
    // Do something
}
```

## Configuration Options

### SideMenuConfiguration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `menuWidth` | `CGFloat` | `0.8` | Width of menu as fraction of screen (0.0 to 1.0) |
| `menuStyle` | `MenuStyle` | `.slideInOut` | Presentation style (`.slideInOver` or `.slideInOut`) |
| `blur` | `CGFloat` | `2` | Maximum blur radius for main content |
| `scale` | `CGFloat` | `1` | Minimum scale for main content (0.0 to 1.0) |
| `dimValue` | `CGFloat` | `0.2` | Opacity of dim overlay (0.0 to 1.0) |
| `menuAnimation` | `Animation` | `.snappy(...)` | Animation curve for transitions |
| `dragActivation` | `MenuDragActivation` | `.full` | Drag area (`.edge` or `.full`) |
| `dragEdgeWidth` | `CGFloat` | `24` | Width of edge drag area in points |
| `dragStartThreshold` | `CGFloat` | `6` | Minimum drag distance to start gesture |
| `openCloseThreshold` | `CGFloat` | `50` | Minimum drag distance to open/close |
| `enableHaptics` | `Bool` | `true` | Enable haptic feedback |

### SideMenuState

Public methods:
- `open()` - Opens the menu
- `close()` - Closes the menu
- `toggle()` - Toggles menu state
- `isOpen` - Bool indicating if menu is open

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
