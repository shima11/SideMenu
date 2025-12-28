
import SwiftUI

// https://medium.com/better-programming/sidemenu-using-swiftui-939a01c86ecd

/// Visual presentation style for the side menu.
public enum MenuStyle: Equatable, Hashable, Sendable {
  /// Menu slides over the main content, which remains in place.
  /// - Parameters:
  ///   - blur: Maximum blur radius applied to main content (default: 2.0)
  ///   - scale: Minimum scale factor applied to main content (default: 1.0)
  ///   - dimValue: Opacity of the dim overlay (default: 0.2)
  case slideInOver(blur: CGFloat = 2, scale: CGFloat = 1, dimValue: CGFloat = 0.2)

  /// Menu and main content both slide together.
  /// - Parameters:
  ///   - dimValue: Opacity of the dim overlay (default: 0.2)
  case slideInOut(dimValue: CGFloat = 0.2)
}

/// Defines which area of the screen can initiate a drag gesture to open the menu.
public enum MenuDragActivation: Equatable, Hashable, Sendable {
  /// Only drags starting from the screen edge can open the menu.
  /// - Parameters:
  ///   - edgeWidth: Width of the edge area in points (default: 24)
  ///   - startThreshold: Minimum drag distance to start in points (default: 6)
  ///   - openCloseThreshold: Minimum drag distance to open/close in points (default: 50)
  case edge(edgeWidth: CGFloat = 24, startThreshold: CGFloat = 6, openCloseThreshold: CGFloat = 50)

  /// Drags starting anywhere on the screen can open the menu.
  /// - Parameters:
  ///   - startThreshold: Minimum drag distance to start in points (default: 6)
  ///   - openCloseThreshold: Minimum drag distance to open/close in points (default: 50)
  case full(startThreshold: CGFloat = 6, openCloseThreshold: CGFloat = 50)
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
///   menuStyle: .slideInOver(blur: 3, scale: 0.95, dimValue: 0.3),
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
  /// Default is `.slideInOut()`.
  public var menuStyle: MenuStyle

  /// Animation curve used for menu transitions.
  ///
  /// Default is `.snappy(duration: 0.35, extraBounce: 0.1)`.
  public var menuAnimation: Animation

  /// Controls which screen area can initiate a drag to open the menu.
  ///
  /// Default is `.full()`.
  public var dragActivation: MenuDragActivation

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
  ///   - menuStyle: Visual presentation style. Default is `.slideInOut()`.
  ///   - menuAnimation: Animation curve for transitions. Default is `.snappy(duration: 0.35, extraBounce: 0.1)`.
  ///   - dragActivation: Which screen area responds to drag gestures. Default is `.full()`.
  ///   - hapticStyle: The style of impact haptic feedback. Set to `nil` to disable. Default is `.medium`.
  ///   - edge: Which screen edge the menu appears from. Default is `.leading`.
  public init(
    menuWidth: CGFloat = 0.8,
    menuStyle: MenuStyle = .slideInOut(),
    menuAnimation: Animation = .easeInOut,
    dragActivation: MenuDragActivation = .full(),
    hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .medium,
    edge: MenuEdge = .leading
  ) {
    self.menuWidth = min(max(menuWidth, 0), 1)
    self.menuStyle = menuStyle
    self.menuAnimation = menuAnimation
    self.dragActivation = dragActivation
    self.hapticStyle = hapticStyle
    self.edge = edge
  }
}

private enum SideMenuLayoutConstants {
  static let minimumWidth: CGFloat = 1
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
    GeometryReader { proxy in
      menuContent(screenWidth: max(proxy.size.width, SideMenuLayoutConstants.minimumWidth))
    }
  }

  // MARK: - Private Methods

  @ViewBuilder
  private func menuContent(screenWidth: CGFloat) -> some View {
    let menuWidthPoints = screenWidth * configuration.menuWidth
    let dragParams = extractDragParams()
    let styleParams = extractStyleParams()
    let calcOffset = calculateOffset(menuWidth: menuWidthPoints)

    HStack(spacing: 0) {
      if styleParams.isSlideInOver {
        slideInOverLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams,
          calcOffset: calcOffset
        )
      } else {
        slideInOutLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams,
          calcOffset: calcOffset
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .simultaneousGesture(
      createDragGesture(menuWidth: menuWidthPoints, dragParams: dragParams)
    )
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
      updateHapticGenerator()
    }
    .onChange(of: configuration.hapticStyle) { _, _ in
      updateHapticGenerator()
    }
    .onDisappear {
      hapticGenerator = nil
    }
  }

  private func updateHapticGenerator() {
    if let style = configuration.hapticStyle {
      hapticGenerator = UIImpactFeedbackGenerator(style: style)
      hapticGenerator?.prepare()
    } else {
      hapticGenerator = nil
    }
  }

  private func extractDragParams() -> (isEdgeOnly: Bool, edgeWidth: CGFloat, startThreshold: CGFloat, openCloseThreshold: CGFloat) {
    switch configuration.dragActivation {
    case .edge(let edgeWidth, let startThreshold, let openCloseThreshold):
      return (true, max(edgeWidth, 0), max(startThreshold, 0), max(openCloseThreshold, 0))
    case .full(let startThreshold, let openCloseThreshold):
      return (false, 0, max(startThreshold, 0), max(openCloseThreshold, 0))
    }
  }

  private func extractStyleParams() -> (isSlideInOver: Bool, blur: CGFloat, scale: CGFloat, dimValue: CGFloat) {
    switch configuration.menuStyle {
    case .slideInOver(let blur, let scale, let dimValue):
      return (true, max(blur, 0), min(max(scale, 0), 1), min(max(dimValue, 0), 1))
    case .slideInOut(let dimValue):
      return (false, 0, 1, min(max(dimValue, 0), 1))
    }
  }

  private func calculateOffset(menuWidth: CGFloat) -> CGFloat {
    let baseOffset = -(menuWidth * CGFloat(model.currentState == .open ? 0 : 1))
    return baseOffset + CGFloat(model.dragOffset)
  }

  private func createDragGesture(
    menuWidth: CGFloat,
    dragParams: (isEdgeOnly: Bool, edgeWidth: CGFloat, startThreshold: CGFloat, openCloseThreshold: CGFloat)
  ) -> some Gesture {
    DragGesture()
      .onChanged { value in
        handleDragChanged(value: value, menuWidth: menuWidth, dragParams: dragParams)
      }
      .onEnded { value in
        handleDragEnded(value: value, dragParams: dragParams)
      }
  }

  private func handleDragChanged(
    value: DragGesture.Value,
    menuWidth: CGFloat,
    dragParams: (isEdgeOnly: Bool, edgeWidth: CGFloat, startThreshold: CGFloat, openCloseThreshold: CGFloat)
  ) {
    let horizontal = abs(value.translation.width)
    let vertical = abs(value.translation.height)

    // Edge-only activation check
    if dragParams.isEdgeOnly && !isMenuOpen && value.startLocation.x > dragParams.edgeWidth {
      if isMenuDragging {
        isMenuDragging = false
      }
      return
    }

    // Horizontal vs vertical gesture check
    guard horizontal > vertical else {
      if isMenuDragging {
        isMenuDragging = false
      }
      return
    }

    // Width boundary check
    guard horizontal <= menuWidth else { return }

    // Prevent dragging closed menu to the left
    guard !(model.currentState == .closed && value.translation.width < 0) else { return }

    // Start dragging if threshold exceeded
    if horizontal > dragParams.startThreshold && !isMenuDragging {
      isMenuDragging = true
    }

    // Handle edge bounce when menu is open and dragging right
    if model.currentState == .open && value.translation.width > 0 {
      withTransaction(Transaction(animation: nil)) {
        model.setDragOffset(SideMenuState.edgeBounceResistance)
      }
      return
    }

    // Update drag offset
    withTransaction(Transaction(animation: nil)) {
      model.setDragOffset(Float(value.translation.width))
    }
  }

  private func handleDragEnded(
    value: DragGesture.Value,
    dragParams: (isEdgeOnly: Bool, edgeWidth: CGFloat, startThreshold: CGFloat, openCloseThreshold: CGFloat)
  ) {
    // Edge-only activation check
    if dragParams.isEdgeOnly && !isMenuOpen && value.startLocation.x > dragParams.edgeWidth {
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

    let shouldClose = value.translation.width < -dragParams.openCloseThreshold
    let shouldOpen = value.translation.width > dragParams.openCloseThreshold
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

    // Trigger haptic feedback if state changed
    let didClose = startingState == .open && shouldClose
    let didOpen = startingState == .closed && shouldOpen
    if didClose || didOpen {
      hapticGenerator?.impactOccurred()
    }
  }

  @ViewBuilder
  private func slideInOverLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: (isSlideInOver: Bool, blur: CGFloat, scale: CGFloat, dimValue: CGFloat),
    calcOffset: CGFloat
  ) -> some View {
    ZStack(alignment: .leading) {
      mainViewWithEffects(
        screenWidth: screenWidth,
        blur: styleParams.blur,
        scale: styleParams.scale,
        offset: 0
      )

      dimOverlay(dimValue: styleParams.dimValue, screenWidth: screenWidth, offset: 0)

      sideMenuView(width: menuWidthPoints, offset: calcOffset)
    }
  }

  @ViewBuilder
  private func slideInOutLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: (isSlideInOver: Bool, blur: CGFloat, scale: CGFloat, dimValue: CGFloat),
    calcOffset: CGFloat
  ) -> some View {
    sideMenuView(width: menuWidthPoints, offset: calcOffset)

    ZStack {
      mainViewWithEffects(
        screenWidth: screenWidth,
        blur: 0,
        scale: 1,
        offset: calcOffset
      )

      dimOverlay(dimValue: styleParams.dimValue, screenWidth: screenWidth, offset: calcOffset)
    }
  }

  @ViewBuilder
  private func mainViewWithEffects(
    screenWidth: CGFloat,
    blur: CGFloat,
    scale: CGFloat,
    offset: CGFloat
  ) -> some View {
    mainView
      .blur(radius: model.calculateBlur(maxValue: blur, totalWidth: screenWidth))
      .scaleEffect(model.calculateScale(minScale: scale, totalWidth: screenWidth))
      .frame(width: screenWidth)
      .offset(x: offset, y: 0)
      .disabled(isMenuDragging)
      .allowsHitTesting(!isMenuDragging)
      .accessibilityFocused($focusTarget, equals: .main)
      .accessibilityHidden(isMenuOpen && offset == 0)
  }

  @ViewBuilder
  private func dimOverlay(dimValue: CGFloat, screenWidth: CGFloat, offset: CGFloat) -> some View {
    Color.clear
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(
        Color.black.opacity(
          Double(model.calculateProgress(totalWidth: screenWidth) * dimValue)
        )
      )
      .offset(x: offset, y: 0)
      .allowsHitTesting(isMenuOpen)
      .onTapGesture {
        if model.isOpen {
          withAnimation(configuration.menuAnimation) { model.close() }
        }
      }
      .accessibilityLabel("Close menu")
      .accessibilityHint("Double tap to close the side menu")
  }

  @ViewBuilder
  private func sideMenuView(width: CGFloat, offset: CGFloat) -> some View {
    sideMenu
      .frame(width: width)
      .offset(x: offset, y: 0)
      .accessibilityFocused($focusTarget, equals: .menu)
      .accessibilityHidden(!isMenuOpen)
      .accessibilityAddTraits(isMenuOpen ? .isModal : [])
  }
}

#Preview {
  struct MinimalExample: View {
    @State private var model = SideMenuState()

    var body: some View {
      SideMenuView(
        model: model
      ) {
        List {
          Section("Menu") {
            Button("Home") { withAnimation { model.close() } }
            Button("Settings") { withAnimation { model.close() } }
            Button("Profile") { withAnimation { model.close() } }
          }
        }
      } mainView: {
        NavigationStack {
          ScrollView {
            VStack(spacing: 12) {
              ForEach(0..<20) { index in
                Text("Item \(index + 1)")
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding()
                  .background(Color(uiColor: .secondarySystemBackground))
                  .clipShape(RoundedRectangle(cornerRadius: 8))
              }
            }
            .padding()
          }
          .navigationTitle("Home")
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button {
                withAnimation { model.toggle() }
              } label: {
                Image(systemName: "line.3.horizontal")
              }
            }
          }
        }
      }
    }
  }

  return MinimalExample()
}
