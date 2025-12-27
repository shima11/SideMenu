
import SwiftUI

// https://medium.com/better-programming/sidemenu-using-swiftui-939a01c86ecd

/// Visual presentation style for the side menu.
public enum MenuStyle: Equatable, Hashable, Sendable {
  /// Menu slides over the main content, which remains in place.
  case slideInOver
  /// Menu and main content both slide together.
  case slideInOut
}

/// Defines which area of the screen can initiate a drag gesture to open the menu.
public enum MenuDragActivation: Equatable, Hashable, Sendable {
  /// Only drags starting from the screen edge (within `dragEdgeWidth`) can open the menu.
  case edge
  /// Drags starting anywhere on the screen can open the menu.
  case full
}

/// Controls how the menu drag gesture competes with other gestures.
public enum MenuGestureHandling: Equatable, Hashable, Sendable {
  /// Allow other gestures (like sliders) to recognize alongside the menu drag.
  case simultaneous
  /// Prefer the menu drag gesture when it recognizes.
  case highPriority
  /// Let the menu drag gesture take exclusive control.
  case exclusive
}

/// Specifies which edge the menu appears from.
public enum MenuEdge: Equatable, Hashable, Sendable {
  /// Menu appears from the leading edge (left in LTR, right in RTL).
  case leading

  // MARK: - Future Features

  /// Menu appears from the trailing edge (right in LTR, left in RTL).
  ///
  /// **Note**: This feature is planned for a future release and is currently not implemented.
  // case trailing
}

/// Configuration options for customizing SideMenu appearance and behavior.
///
/// All visual parameters are automatically validated and clamped to safe ranges.
///
/// Example:
/// ```swift
/// let config = SideMenuConfiguration(
///   menuWidth: 0.7,
///   menuStyle: .slideInOver,
///   blur: 3,
///   hapticStyle: .medium
/// )
/// ```
public struct SideMenuConfiguration: Equatable, Sendable {

  /// Width of the menu as a fraction of screen width (0.0 to 1.0).
  ///
  /// Values outside this range are automatically clamped. Default is 0.8 (80% of screen).
  public var menuWidth: CGFloat

  /// Visual presentation style of the menu.
  ///
  /// Default is `.slideInOut`.
  public var menuStyle: MenuStyle

  /// Maximum blur radius applied to main content when menu is open.
  ///
  /// Negative values are clamped to 0. Default is 2.0.
  public var blur: CGFloat

  /// Minimum scale factor applied to main content when menu is fully open (0.0 to 1.0).
  ///
  /// Values outside this range are automatically clamped. Default is 1.0 (no scaling).
  public var scale: CGFloat

  /// Opacity of the dim overlay when menu is open (0.0 to 1.0).
  ///
  /// Values outside this range are automatically clamped. Default is 0.2.
  public var dimValue: CGFloat

  /// Animation curve used for menu transitions.
  ///
  /// Default is `.snappy(duration: 0.35, extraBounce: 0.1)`.
  public var menuAnimation: Animation

  /// Controls which screen area can initiate a drag to open the menu.
  ///
  /// Default is `.full`.
  public var dragActivation: MenuDragActivation

  /// Width of the edge area (in points) that responds to drag gestures when `dragActivation` is `.edge`.
  ///
  /// Negative values are clamped to 0. Default is 24.0 points.
  public var dragEdgeWidth: CGFloat

  /// Minimum horizontal drag distance (in points) before the gesture is recognized as a menu drag.
  ///
  /// Negative values are clamped to 0. Default is 6.0 points.
  public var dragStartThreshold: CGFloat

  /// Minimum drag distance (in points) required to open or close the menu when the gesture ends.
  ///
  /// Negative values are clamped to 0. Default is 50.0 points.
  public var openCloseThreshold: CGFloat

  /// How the menu drag gesture competes with other gestures like sliders.
  ///
  /// Default is `.simultaneous`.
  public var gestureHandling: MenuGestureHandling

  /// The style of impact haptic feedback when opening or closing the menu via gesture.
  ///
  /// Set to `nil` to disable haptic feedback. Default is `.medium`.
  public var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle?

  /// Edge of the screen from which the menu appears.
  ///
  /// **Note**: Currently only `.leading` is fully supported. `.trailing` support is planned for a future release.
  ///
  /// Default is `.leading`.
  public var edge: MenuEdge

  /// Creates a new side menu configuration.
  ///
  /// - Parameters:
  ///   - menuWidth: Width of the menu as a fraction of screen width (0.0 to 1.0). Default is 0.8.
  ///   - menuStyle: Visual presentation style. Default is `.slideInOut`.
  ///   - blur: Maximum blur radius for main content. Default is 2.0.
  ///   - scale: Minimum scale factor for main content (0.0 to 1.0). Default is 1.0.
  ///   - dimValue: Dim overlay opacity (0.0 to 1.0). Default is 0.2.
  ///   - menuAnimation: Animation curve for transitions. Default is `.snappy(duration: 0.35, extraBounce: 0.1)`.
  ///   - dragActivation: Which screen area responds to drag gestures. Default is `.full`.
  ///   - dragEdgeWidth: Width of edge drag area in points. Default is 24.0.
  ///   - dragStartThreshold: Minimum drag distance to start in points. Default is 6.0.
  ///   - openCloseThreshold: Minimum drag distance to open/close in points. Default is 50.0.
  ///   - gestureHandling: How the menu drag gesture competes with other gestures. Default is `.simultaneous`.
  ///   - hapticStyle: The style of impact haptic feedback. Set to `nil` to disable. Default is `.medium`.
  ///   - edge: Which screen edge the menu appears from. Default is `.leading`.
  public init(
    menuWidth: CGFloat = 0.8,
    menuStyle: MenuStyle = .slideInOut,
    blur: CGFloat = 2,
    scale: CGFloat = 1,
    dimValue: CGFloat = 0.2,
    menuAnimation: Animation = .snappy(duration: 0.35, extraBounce: 0.1),
    dragActivation: MenuDragActivation = .full,
    dragEdgeWidth: CGFloat = 24,
    dragStartThreshold: CGFloat = 6,
    openCloseThreshold: CGFloat = 50,
    gestureHandling: MenuGestureHandling = .simultaneous,
    hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .medium,
    edge: MenuEdge = .leading
  ) {
    self.menuWidth = min(max(menuWidth, 0), 1)
    self.menuStyle = menuStyle
    self.blur = max(blur, 0)
    self.scale = min(max(scale, 0), 1)
    self.dimValue = min(max(dimValue, 0), 1)
    self.menuAnimation = menuAnimation
    self.dragActivation = dragActivation
    self.dragEdgeWidth = max(dragEdgeWidth, 0)
    self.dragStartThreshold = max(dragStartThreshold, 0)
    self.openCloseThreshold = max(openCloseThreshold, 0)
    self.gestureHandling = gestureHandling
    self.hapticStyle = hapticStyle
    self.edge = edge
  }
}

/// A customizable side menu component with gesture support and accessibility features.
///
/// `SideMenuView` provides a sliding side menu with extensive customization options,
/// smooth animations, and full accessibility support including VoiceOver.
///
/// Example:
/// ```swift
/// @State private var menuState = SideMenuState()
///
/// var body: some View {
///   SideMenuView(
///     model: menuState,
///     configuration: SideMenuConfiguration(
///       menuWidth: 0.8,
///       menuStyle: .slideInOver
///     )
///   ) {
///     // Side menu content
///     MenuView()
///   } mainView: {
///     // Main content
///     ContentView()
///   }
/// }
/// ```
public struct SideMenuView<SideMenu : View, MainView : View> : View {

  // MARK: - Public Properties

  /// The side menu content.
  public let sideMenu: SideMenu

  /// The main view content.
  public let mainView: MainView

  /// Configuration options for the menu's appearance and behavior.
  public let configuration: SideMenuConfiguration

  /// The state model managing menu open/close state.
  @Bindable public var model: SideMenuState

  // MARK: - Private Properties

  @AccessibilityFocusState private var focusTarget: FocusTarget?
  @State private var isMenuDragging = false
  @State private var hapticGenerator: UIImpactFeedbackGenerator?

  private enum FocusTarget: Hashable {
    case menu
    case main
  }

  private var isMenuOpen: Bool {
    model.currentState == .open
  }

  // MARK: - Initialization

  /// Creates a new side menu view.
  ///
  /// - Parameters:
  ///   - model: The state model managing the menu. Default is a new instance.
  ///   - configuration: Configuration options for appearance and behavior. Default uses standard values.
  ///   - sideMenu: A view builder for the side menu content.
  ///   - mainView: A view builder for the main content.
  @inlinable public init(
    model: SideMenuState = .init(),
    configuration: SideMenuConfiguration = .init(),
    @ViewBuilder sideMenu: () -> SideMenu,
    @ViewBuilder mainView: () -> MainView
  ) {
    self.model = model
    self.sideMenu = sideMenu()
    self.mainView = mainView()
    self.configuration = configuration
  }
  
  // MARK: - Body

  public var body: some View {
    return GeometryReader { proxy in
      let screenWidth = max(proxy.size.width, 1)
      let menuWidthPoints = screenWidth * configuration.menuWidth
      let dragGesture = DragGesture()
        .onChanged { value in
          let horizontal = abs(value.translation.width)
          let vertical = abs(value.translation.height)
          let isEdgeOnly = configuration.dragActivation == .edge
          let isOpeningFromEdge = isEdgeOnly && !isMenuOpen && value.startLocation.x > configuration.dragEdgeWidth

          if isOpeningFromEdge {
            if isMenuDragging {
              isMenuDragging = false
            }
            return
          }
          guard horizontal > vertical else {
            if isMenuDragging {
              isMenuDragging = false
            }
            return
          }
          guard horizontal <= menuWidthPoints else { return }
          guard !(model.currentState == .closed && value.translation.width < 0) else { return }
          if horizontal > configuration.dragStartThreshold && !isMenuDragging {
            isMenuDragging = true
          }
          if model.currentState == .open && value.translation.width > 0 {
            withTransaction(Transaction(animation: nil)) {
              model.setDragOffset(SideMenuState.edgeBounceResistance)
            }
            return
          }
          withTransaction(Transaction(animation: nil)) {
            model.setDragOffset(Float(value.translation.width))
          }
        }
        .onEnded { value in
          let isEdgeOnly = configuration.dragActivation == .edge
          let isOpeningFromEdge = isEdgeOnly && !isMenuOpen && value.startLocation.x > configuration.dragEdgeWidth
          if isOpeningFromEdge {
            if isMenuDragging {
              isMenuDragging = false
            }
            withTransaction(Transaction(animation: configuration.menuAnimation)) {
              model.resetDragOffset()
            }
            return
          }
          if isMenuDragging {
            isMenuDragging = false
          }
          let shouldClose = value.translation.width < -configuration.openCloseThreshold
          let shouldOpen = value.translation.width > configuration.openCloseThreshold
          let startingState = model.currentState

          withTransaction(Transaction(animation: configuration.menuAnimation)) {
            model.resetDragOffset()
            if shouldClose {
              model.close()
            }
            if shouldOpen {
              model.open()
            }
          }

          let didClose = startingState == .open && shouldClose
          let didOpen = startingState == .closed && shouldOpen
          if didClose || didOpen {
            hapticGenerator?.impactOccurred()
          }
        }

      // Calculate offset (currently only supports leading edge)
      let baseOffset = -(menuWidthPoints * CGFloat(model.currentState == .open ? 0 : 1))
      let calcOffset = baseOffset + CGFloat(model.dragOffset)

      HStack (spacing: 0) {
        if configuration.menuStyle == .slideInOver {
          ZStack(alignment: .leading) {
            mainView
              .blur(radius: model.calculateBlur(maxValue: configuration.blur, totalWidth: screenWidth))
              .scaleEffect(model.calculateScale(minScale: configuration.scale, totalWidth: screenWidth))
              .frame(width: screenWidth)
              .disabled(isMenuDragging)
              .allowsHitTesting(!isMenuDragging)
              .accessibilityFocused($focusTarget, equals: .main)
              .accessibilityHidden(isMenuOpen)

            Color.clear
              .frame(maxWidth: .infinity,  maxHeight: .infinity)
              .overlay(Color.black.opacity(Double(model.calculateBlur(maxValue: configuration.dimValue, totalWidth: screenWidth))))
              .allowsHitTesting(isMenuOpen)
              .onTapGesture {
                if model.isOpen {
                  withAnimation(configuration.menuAnimation) { model.close() }
                }
              }

            sideMenu
              .frame(width: menuWidthPoints)
              .offset(x: calcOffset, y: 0)
              .accessibilityFocused($focusTarget, equals: .menu)
              .accessibilityHidden(!isMenuOpen)
              .accessibilityAddTraits(isMenuOpen ? .isModal : [])
          }

        } else {
            sideMenu
              .frame(width: menuWidthPoints)
              .offset(x: calcOffset, y: 0)
              .accessibilityFocused($focusTarget, equals: .menu)
              .accessibilityHidden(!isMenuOpen)

            ZStack {
              mainView
                .frame(width: screenWidth)
                .offset(x: calcOffset, y: 0)
                .disabled(isMenuDragging)
                .allowsHitTesting(!isMenuDragging)
                .accessibilityFocused($focusTarget, equals: .main)

              Color.clear
                .frame(maxWidth: .infinity,  maxHeight: .infinity)
                .overlay(Color.black.opacity(Double(model.calculateBlur(maxValue: configuration.dimValue, totalWidth: screenWidth))))
                .offset(x: calcOffset, y: 0)
                .allowsHitTesting(isMenuOpen)
                .onTapGesture {
                  if model.isOpen {
                    withAnimation(configuration.menuAnimation) { model.close() }
                  }
                }
            }
          }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .simultaneousGesture(dragGesture)
    .accessibilityAction(.escape) {
      guard isMenuOpen else { return }
      withAnimation(configuration.menuAnimation) {
        model.close()
      }
    }
    .accessibilityAction(named: "Close Menu") {
      guard isMenuOpen else { return }
      withAnimation(configuration.menuAnimation) {
        model.close()
      }
    }
    .onChange(of: model.currentState) { _, newValue in
      focusTarget = (newValue == .open) ? .menu : .main
    }
    .onAppear {
      if let style = configuration.hapticStyle {
        hapticGenerator = UIImpactFeedbackGenerator(style: style)
        hapticGenerator?.prepare()
      }
    }
    .onDisappear {
      hapticGenerator = nil
    }
    }
  }
}

#Preview {
  SideMenuPreview()
}

private struct SideMenuPreview: View {
  
  enum Menu: String, CaseIterable {
    case room1, room2, room3
  }
  
  private enum PreviewAnimationStyle: String, CaseIterable, Identifiable {
    case snappy
    case spring
    case easeInOut

    var id: String { rawValue }
  }

  @State private var model = SideMenuState()
  @State private var selectedMenu: Menu = .room1
  @State private var configuration = SideMenuConfiguration()
  @State private var animationStyle: PreviewAnimationStyle = .snappy
  @State private var animationDuration: Double = 0.35
  @State private var animationBounce: Double = 0.1

  @State var showDetail = false

  private var menuAnimation: Animation {
    switch animationStyle {
    case .snappy:
      return .snappy(duration: animationDuration, extraBounce: animationBounce)
    case .spring:
      return .spring(duration: animationDuration, bounce: animationBounce)
    case .easeInOut:
      return .easeInOut(duration: animationDuration)
    }
  }

  var body: some View {
    SideMenuView(
      model: model,
      configuration: SideMenuConfiguration(
        menuWidth: configuration.menuWidth,
        menuStyle: configuration.menuStyle,
        blur: configuration.blur,
        scale: configuration.scale,
        dimValue: configuration.dimValue,
        menuAnimation: menuAnimation,
        dragActivation: configuration.dragActivation,
        dragEdgeWidth: configuration.dragEdgeWidth,
        dragStartThreshold: configuration.dragStartThreshold,
        openCloseThreshold: configuration.openCloseThreshold,
        gestureHandling: configuration.gestureHandling,
        hapticStyle: configuration.hapticStyle
      )
    ) {
      ZStack {
        Color(uiColor: .systemBackground)
        NavigationStack {
          List {
            Section("Room") {
              ForEach(Menu.allCases, id: \.self) { item in
                Button(item.rawValue) {
                  withAnimation(menuAnimation) {
                    selectedMenu = item
                    if model.isOpen {
                      model.close()
                    }
                  }
                }
              }
            }
            
            Section {
              Picker("Drag", selection: $configuration.dragActivation) {
                Text("Full").tag(MenuDragActivation.full)
                Text("Edge").tag(MenuDragActivation.edge)
              }
              Picker("Gesture", selection: $configuration.gestureHandling) {
                Text("Simultaneous").tag(MenuGestureHandling.simultaneous)
                Text("Priority").tag(MenuGestureHandling.highPriority)
                Text("Exclusive").tag(MenuGestureHandling.exclusive)
              }
              PreviewValueSlider(
                title: "Edge Width",
                value: $configuration.dragEdgeWidth.asDouble(),
                range: 0...80,
                step: 2
              )
              .disabled(configuration.dragActivation == .full)
              PreviewValueSlider(
                title: "Drag Start",
                value: $configuration.dragStartThreshold.asDouble(),
                range: 0...20,
                step: 1
              )
              PreviewValueSlider(
                title: "Open/Close",
                value: $configuration.openCloseThreshold.asDouble(),
                range: 20...120,
                step: 5
              )
              Picker("Haptic", selection: $configuration.hapticStyle) {
                Text("None").tag(nil as UIImpactFeedbackGenerator.FeedbackStyle?)
                Text("Light").tag(UIImpactFeedbackGenerator.FeedbackStyle.light as UIImpactFeedbackGenerator.FeedbackStyle?)
                Text("Medium").tag(UIImpactFeedbackGenerator.FeedbackStyle.medium as UIImpactFeedbackGenerator.FeedbackStyle?)
                Text("Heavy").tag(UIImpactFeedbackGenerator.FeedbackStyle.heavy as UIImpactFeedbackGenerator.FeedbackStyle?)
                Text("Soft").tag(UIImpactFeedbackGenerator.FeedbackStyle.soft as UIImpactFeedbackGenerator.FeedbackStyle?)
                Text("Rigid").tag(UIImpactFeedbackGenerator.FeedbackStyle.rigid as UIImpactFeedbackGenerator.FeedbackStyle?)
              }
              Picker("Style", selection: $configuration.menuStyle) {
                Text("Slide In Over").tag(MenuStyle.slideInOver)
                Text("Slide In Out").tag(MenuStyle.slideInOut)
              }
              Picker("Animation", selection: $animationStyle) {
                ForEach(PreviewAnimationStyle.allCases) { style in
                  Text(style.rawValue).tag(style)
                }
              }
              .textCase(nil)
              PreviewValueSlider(
                title: "Duration",
                value: $animationDuration,
                range: 0.15...1.0,
                step: 0.05
              )
              PreviewValueSlider(
                title: "Bounce",
                value: $animationBounce,
                range: 0...0.9,
                step: 0.05
              )
              .disabled(animationStyle == .easeInOut)
              PreviewValueSlider(
                title: "Menu Width",
                value: $configuration.menuWidth.asDouble(),
                range: 0.3...0.9,
                step: 0.05
              )
              PreviewValueSlider(
                title: "Blur",
                value: $configuration.blur.asDouble(),
                range: 0...10,
                step: 0.5
              )
              PreviewValueSlider(
                title: "Scale",
                value: $configuration.scale.asDouble(),
                range: 0.8...1.0,
                step: 0.02
              )
              PreviewValueSlider(
                title: "Dim",
                value: $configuration.dimValue.asDouble(),
                range: 0...0.6,
                step: 0.05
              )
            }

          }
          .navigationTitle(Text("Menu"))
        }
      }
    } mainView: {
      NavigationStack {
        ScrollView {
          VStack(spacing: 4) {
            ForEach(0..<30) { index in
              Button {
                print("Tap \(index)")
                showDetail = true
              } label: {
                HStack {
                  Text("Row \(index)")
                  Spacer()
                  Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 24)
        }
        .navigationTitle(Text("Room: \(selectedMenu.rawValue)"))
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("", systemImage: "line.3.horizontal") {
              withAnimation(menuAnimation) {
                model.toggle()
              }
            }
          }
        }
        .sheet(isPresented: $showDetail) {
          Text("Detail")
        }
      }
    }
  }
}

private struct PreviewValueSlider: View {
  let title: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(title)
        Spacer()
        Text(value, format: .number.precision(.fractionLength(2)))
          .foregroundStyle(.secondary)
      }
      Slider(value: $value, in: range, step: step)
    }
  }
}

private extension Binding where Value == CGFloat {
  func asDouble() -> Binding<Double> {
    Binding<Double>(
      get: { Double(wrappedValue) },
      set: { wrappedValue = CGFloat($0) }
    )
  }
}
