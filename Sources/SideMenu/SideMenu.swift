
import SwiftUI

/// Context information passed to custom layout closures.
public struct CustomLayoutContext: Sendable {
  /// The total width of the screen.
  public let screenWidth: CGFloat

  /// The width of the side menu.
  public let menuWidth: CGFloat

  /// The current offset value based on drag and open/close state.
  public let offset: CGFloat

  /// The progress of the menu animation (0 = closed, 1 = open).
  public let progress: CGFloat

  /// Whether the menu is currently open.
  public let isOpen: Bool

  /// Whether the user is currently dragging.
  public let isDragging: Bool
}

/// Visual presentation style for the side menu.
public enum MenuStyle: Sendable {
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

  /// Main content slides out to reveal the menu underneath (like Meta Threads).
  /// Menu stays fixed in place while main content moves to expose it.
  /// - Parameters:
  ///   - scale: Minimum scale factor applied to side menu (default: 0.9)
  ///   - dimValue: Opacity of the dim overlay (default: 0.2)
  ///   - backgroundColor: Background color shown behind the menu during scale animation
  case slideOut(scale: CGFloat = 0.9, dimValue: CGFloat = 0.2, backgroundColor: UIColor? = nil)

  /// Custom layout with user-defined closures for side menu and main view.
  /// - Parameters:
  ///   - dimValue: Opacity of the dim overlay (default: 0.2)
  ///   - sideMenuLayout: Closure to customize the side menu layout
  ///   - mainViewLayout: Closure to customize the main view layout
  case custom(
    dimValue: CGFloat = 0.2,
    sideMenuLayout: @Sendable (CustomLayoutContext, AnyView) -> AnyView,
    mainViewLayout: @Sendable (CustomLayoutContext, AnyView) -> AnyView
  )
}

// MARK: - MenuStyle Equatable & Hashable

extension MenuStyle: Equatable {
  public static func == (lhs: MenuStyle, rhs: MenuStyle) -> Bool {
    switch (lhs, rhs) {
    case (.slideInOver(let b1, let s1, let d1), .slideInOver(let b2, let s2, let d2)):
      return b1 == b2 && s1 == s2 && d1 == d2
    case (.slideInOut(let d1), .slideInOut(let d2)):
      return d1 == d2
    case (.slideOut(let s1, let d1, let bg1), .slideOut(let s2, let d2, let bg2)):
      return s1 == s2 && d1 == d2 && bg1 == bg2
    case (.custom, .custom):
      return false  // Closures cannot be compared
    default:
      return false
    }
  }
}

extension MenuStyle: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .slideInOver(let blur, let scale, let dim):
      hasher.combine(0)
      hasher.combine(blur)
      hasher.combine(scale)
      hasher.combine(dim)
    case .slideInOut(let dim):
      hasher.combine(1)
      hasher.combine(dim)
    case .slideOut(let scale, let dim, let bg):
      hasher.combine(2)
      hasher.combine(scale)
      hasher.combine(dim)
      hasher.combine(bg)
    case .custom(let dim, _, _):
      hasher.combine(3)
      hasher.combine(dim)
    }
  }
}

/// Defines which area of the screen can initiate a drag gesture to open the menu.
public enum MenuDragActivation: Equatable, Hashable, Sendable {
  /// Only drags starting from the screen edge can open the menu.
  /// - Parameters:
  ///   - edgeWidth: Width of the edge area in points (default: 24)
  ///   - startThreshold: Minimum drag distance to start in points (default: 15)
  ///   - openCloseThreshold: Minimum drag distance to open/close in points (default: 50)
  ///   - directionRatio: Required horizontal/vertical ratio to recognize as horizontal drag (default: 1.5)
  case edge(edgeWidth: CGFloat = 24, startThreshold: CGFloat = 15, openCloseThreshold: CGFloat = 50, directionRatio: CGFloat = 1.5)

  /// Drags starting anywhere on the screen can open the menu.
  /// - Parameters:
  ///   - startThreshold: Minimum drag distance to start in points (default: 15)
  ///   - openCloseThreshold: Minimum drag distance to open/close in points (default: 50)
  ///   - directionRatio: Required horizontal/vertical ratio to recognize as horizontal drag (default: 1.5)
  case full(startThreshold: CGFloat = 15, openCloseThreshold: CGFloat = 50, directionRatio: CGFloat = 1.5)
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
  /// Default is `.spring(duration: 0.4, bounce: 0.0)` for physically-based motion.
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

  /// Minimum flick velocity (pt/s) to trigger open/close regardless of distance.
  ///
  /// Default is 300.
  public var velocityThreshold: CGFloat

  /// Maximum visual displacement for rubber band effect at menu edges.
  ///
  /// Default is 40.
  public var rubberBandLimit: CGFloat

  /// Creates a new side menu configuration.
  ///
  /// - Parameters:
  ///   - menuWidth: Width of the menu as a fraction of screen width (0.0 to 1.0). Default is 0.8.
  ///   - menuStyle: Visual presentation style. Default is `.slideOut()`.
  ///   - menuAnimation: Animation curve for transitions. Default is `.spring(duration: 0.4, bounce: 0.0)`.
  ///   - dragActivation: Which screen area responds to drag gestures. Default is `.full()`.
  ///   - hapticStyle: The style of impact haptic feedback. Set to `nil` to disable. Default is `.medium`.
  ///   - edge: Which screen edge the menu appears from. Default is `.leading`.
  ///   - velocityThreshold: Minimum flick velocity to trigger open/close. Default is 300.
  ///   - rubberBandLimit: Maximum rubber band displacement in points. Default is 40.
  public init(
    menuWidth: CGFloat = 0.8,
    menuStyle: MenuStyle = .slideInOut(),
    menuAnimation: Animation = .spring(duration: 0.4, bounce: 0.0),
    dragActivation: MenuDragActivation = .full(),
    hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .medium,
    edge: MenuEdge = .leading,
    velocityThreshold: CGFloat = 300,
    rubberBandLimit: CGFloat = 40
  ) {
    self.menuWidth = min(max(menuWidth, 0), 1)
    self.menuStyle = menuStyle
    self.menuAnimation = menuAnimation
    self.dragActivation = dragActivation
    self.hapticStyle = hapticStyle
    self.edge = edge
    self.velocityThreshold = max(velocityThreshold, 0)
    self.rubberBandLimit = max(rubberBandLimit, 0)
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
  @State private var hasReachedRubberBandLimit = false
  @State private var hapticGenerator: UIImpactFeedbackGenerator?
  @State private var lightHapticGenerator: UIImpactFeedbackGenerator?
  @State private var rigidHapticGenerator: UIImpactFeedbackGenerator?

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
      switch styleParams.styleType {
      case .slideInOver:
        slideInOverLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams,
          calcOffset: calcOffset
        )
      case .slideInOut:
        slideInOutLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams,
          calcOffset: calcOffset
        )
      case .slideOut:
        slideOutLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams,
          calcOffset: calcOffset
        )
      case .custom:
        customLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams,
          calcOffset: calcOffset
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .simultaneousGesture(
      createDragGesture(menuWidth: menuWidthPoints, dragParams: dragParams),
      including: (!isMenuOpen && !dragParams.isEdgeOnly) ? .all : .none
    )
    .overlay(alignment: .leading) {
      if dragParams.isEdgeOnly && !isMenuOpen {
        Color.clear
          .frame(width: dragParams.edgeWidth)
          .frame(maxHeight: .infinity)
          .contentShape(Rectangle())
          .gesture(createDragGesture(menuWidth: menuWidthPoints, dragParams: dragParams))
      }
    }
    .accessibilityAction(.escape, closeMenuWithAnimation)
    .accessibilityAction(named: "Close Menu", closeMenuWithAnimation)
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
      lightHapticGenerator = nil
      rigidHapticGenerator = nil
    }
  }

  private func closeMenuWithAnimation() {
    guard isMenuOpen else { return }
    withAnimation(configuration.menuAnimation) {
      model.close()
    }
  }

  private func updateHapticGenerator() {
    if let style = configuration.hapticStyle {
      hapticGenerator = UIImpactFeedbackGenerator(style: style)
      hapticGenerator?.prepare()
      lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
      lightHapticGenerator?.prepare()
      rigidHapticGenerator = UIImpactFeedbackGenerator(style: .rigid)
      rigidHapticGenerator?.prepare()
    } else {
      hapticGenerator = nil
      lightHapticGenerator = nil
      rigidHapticGenerator = nil
    }
  }

  private struct DragParams {
    let isEdgeOnly: Bool
    let edgeWidth: CGFloat
    let startThreshold: CGFloat
    let openCloseThreshold: CGFloat
    let directionRatio: CGFloat

    func shouldIgnoreDrag(isMenuOpen: Bool, startLocationX: CGFloat) -> Bool {
      isEdgeOnly && !isMenuOpen && startLocationX > edgeWidth
    }
  }

  private func extractDragParams() -> DragParams {
    switch configuration.dragActivation {
    case .edge(let edgeWidth, let startThreshold, let openCloseThreshold, let directionRatio):
      return DragParams(
        isEdgeOnly: true,
        edgeWidth: max(edgeWidth, 0),
        startThreshold: max(startThreshold, 0),
        openCloseThreshold: max(openCloseThreshold, 0),
        directionRatio: max(directionRatio, 1.0)
      )
    case .full(let startThreshold, let openCloseThreshold, let directionRatio):
      return DragParams(
        isEdgeOnly: false,
        edgeWidth: 0,
        startThreshold: max(startThreshold, 0),
        openCloseThreshold: max(openCloseThreshold, 0),
        directionRatio: max(directionRatio, 1.0)
      )
    }
  }

  private enum StyleType {
    case slideInOver
    case slideInOut
    case slideOut
    case custom
  }

  private struct StyleParams {
    let styleType: StyleType
    let blur: CGFloat
    let scale: CGFloat
    let dimValue: CGFloat
    let backgroundColor: UIColor?
  }

  private func extractStyleParams() -> StyleParams {
    switch configuration.menuStyle {
    case .slideInOver(let blur, let scale, let dimValue):
      return StyleParams(
        styleType: .slideInOver,
        blur: max(blur, 0),
        scale: min(max(scale, 0), 1),
        dimValue: min(max(dimValue, 0), 1),
        backgroundColor: nil
      )
    case .slideInOut(let dimValue):
      return StyleParams(
        styleType: .slideInOut,
        blur: 0,
        scale: 1,
        dimValue: min(max(dimValue, 0), 1),
        backgroundColor: nil
      )
    case .slideOut(let scale, let dimValue, let backgroundColor):
      return StyleParams(
        styleType: .slideOut,
        blur: 0,
        scale: min(max(scale, 0), 1),
        dimValue: min(max(dimValue, 0), 1),
        backgroundColor: backgroundColor
      )
    case .custom(let dimValue, _, _):
      return StyleParams(
        styleType: .custom,
        blur: 0,
        scale: 1,
        dimValue: min(max(dimValue, 0), 1),
        backgroundColor: nil
      )
    }
  }

  private func calculateOffset(menuWidth: CGFloat) -> CGFloat {
    let baseOffset = -(menuWidth * CGFloat(model.currentState == .open ? 0 : 1))
    return baseOffset + CGFloat(model.dragOffset)
  }

  private func createDragGesture(
    menuWidth: CGFloat,
    dragParams: DragParams
  ) -> some Gesture {
    DragGesture(minimumDistance: dragParams.startThreshold)
      .onChanged { value in
        handleDragChanged(value: value, menuWidth: menuWidth, dragParams: dragParams)
      }
      .onEnded { value in
        handleDragEnded(value: value, dragParams: dragParams, menuWidth: menuWidth)
      }
  }

  private func handleDragChanged(
    value: DragGesture.Value,
    menuWidth: CGFloat,
    dragParams: DragParams
  ) {
    let horizontal = abs(value.translation.width)
    let vertical = abs(value.translation.height)

    // Edge-only activation check
    if dragParams.shouldIgnoreDrag(isMenuOpen: isMenuOpen, startLocationX: value.startLocation.x) {
      isMenuDragging = false
      return
    }

    // Horizontal vs vertical gesture check (require clear horizontal intent)
    guard horizontal > vertical * dragParams.directionRatio else {
      isMenuDragging = false
      return
    }

    // Start dragging only after sufficient horizontal movement
    if horizontal > dragParams.startThreshold && !isMenuDragging {
      isMenuDragging = true
    }

    // Ignore until dragging is confirmed
    guard isMenuDragging else { return }

    // Rubber band: closed state dragging left
    if model.currentState == .closed && value.translation.width < 0 {
      let rubberOffset = SideMenuState.rubberBand(
        offset: abs(value.translation.width),
        limit: configuration.rubberBandLimit
      )
      withTransaction(Transaction(animation: nil)) {
        model.setDragOffset(-Float(rubberOffset))
      }
      return
    }

    // Rubber band: open state dragging right (overdrag)
    if model.currentState == .open && value.translation.width > 0 {
      let rubberOffset = SideMenuState.rubberBand(
        offset: value.translation.width,
        limit: configuration.rubberBandLimit
      )
      withTransaction(Transaction(animation: nil)) {
        model.setDragOffset(Float(rubberOffset))
      }
      // Haptic once at rubber band limit
      if value.translation.width > configuration.rubberBandLimit && !hasReachedRubberBandLimit {
        hasReachedRubberBandLimit = true
        rigidHapticGenerator?.impactOccurred()
      } else if value.translation.width <= configuration.rubberBandLimit {
        hasReachedRubberBandLimit = false
      }
      return
    }

    // Width boundary check
    guard horizontal <= menuWidth else { return }

    // Update drag offset (cancel animation for immediate tracking)
    withTransaction(Transaction(animation: nil)) {
      model.setDragOffset(Float(value.translation.width))
    }

    // Threshold crossing haptic (50% of menu width)
    if configuration.hapticStyle != nil {
      let progress: CGFloat
      if model.currentState == .open {
        // Closing: progress from 1→0, threshold at 0.5
        progress = 1.0 + CGFloat(value.translation.width) / menuWidth
      } else {
        // Opening: progress from 0→1, threshold at 0.5
        progress = CGFloat(value.translation.width) / menuWidth
      }
      let pastThreshold = progress > 0.5
      if pastThreshold != model.hasPassedThreshold {
        model.hasPassedThreshold = pastThreshold
        lightHapticGenerator?.impactOccurred()
      }
    }
  }

  private func handleDragEnded(
    value: DragGesture.Value,
    dragParams: DragParams,
    menuWidth: CGFloat
  ) {
    // Edge-only activation check
    if dragParams.shouldIgnoreDrag(isMenuOpen: isMenuOpen, startLocationX: value.startLocation.x) {
      isMenuDragging = false
      withTransaction(Transaction(animation: configuration.menuAnimation)) {
        model.resetDragOffset()
      }
      return
    }

    // If drag was never confirmed as horizontal, just reset
    if !isMenuDragging {
      withTransaction(Transaction(animation: configuration.menuAnimation)) {
        model.resetDragOffset()
      }
      return
    }

    isMenuDragging = false
    hasReachedRubberBandLimit = false
    model.hasPassedThreshold = false

    let velocityX = value.velocity.width
    let startingState = model.currentState

    // Current position of the menu edge
    let currentPosition: CGFloat
    if startingState == .open {
      currentPosition = menuWidth + CGFloat(value.translation.width)
    } else {
      currentPosition = CGFloat(value.translation.width)
    }

    // Velocity-based snap: if flick is fast enough, decide by direction
    let shouldOpen: Bool
    let shouldClose: Bool
    if abs(velocityX) > configuration.velocityThreshold {
      shouldOpen = velocityX > 0
      shouldClose = velocityX < 0
    } else {
      // Position-based fallback: 50% of menu width
      shouldOpen = currentPosition > menuWidth * 0.5
      shouldClose = currentPosition <= menuWidth * 0.5
    }

    // Remaining distance to target
    let targetPosition: CGFloat = (shouldOpen ? menuWidth : 0)
    let remainingDistance = targetPosition - currentPosition

    // Fluid Interface: normalizedVelocity = gestureVelocity / remainingDistance
    // This ensures the spring animation starts at exactly the gesture's velocity
    let normalizedVelocity: Double
    if abs(remainingDistance) > 1 {
      normalizedVelocity = velocityX / remainingDistance
    } else {
      normalizedVelocity = 0
    }

    var transaction = Transaction()
    transaction.animation = .interpolatingSpring(
      mass: 1.0,
      stiffness: 200,
      damping: 25,
      initialVelocity: normalizedVelocity
    )

    withTransaction(transaction) {
      model.resetDragOffset()
      if shouldClose {
        model.close()
      } else if shouldOpen {
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
    styleParams: StyleParams,
    calcOffset: CGFloat
  ) -> some View {
    ZStack(alignment: .leading) {
      mainViewWithEffects(
        screenWidth: screenWidth,
        blur: styleParams.blur,
        scale: styleParams.scale,
        offset: 0
      )

      dimOverlay(dimValue: styleParams.dimValue, menuWidth: menuWidthPoints, offset: 0)

      sideMenuView(width: menuWidthPoints, offset: calcOffset)
    }
  }

  @ViewBuilder
  private func slideInOutLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: StyleParams,
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

      dimOverlay(dimValue: styleParams.dimValue, menuWidth: menuWidthPoints, offset: calcOffset)
    }
  }

  @ViewBuilder
  private func slideOutLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: StyleParams,
    calcOffset: CGFloat
  ) -> some View {
    // Menu is underneath, fixed in place
    // MainView slides to reveal the menu
    ZStack(alignment: .leading) {
      // Background to prevent gaps when scaling
      if let backgroundColor = styleParams.backgroundColor {
        Color(uiColor: backgroundColor)
          .frame(width: menuWidthPoints)
          .ignoresSafeArea()
      }
      
      sideMenuView(width: menuWidthPoints, offset: 0)
        .scaleEffect(
          model.calculateMenuScale(minScale: styleParams.scale, menuWidth: menuWidthPoints),
          anchor: .trailing
        )

      ZStack {
        mainViewWithEffects(
          screenWidth: screenWidth,
          blur: 0,
          scale: 1,
          offset: calcOffset + menuWidthPoints
        )

        dimOverlay(dimValue: styleParams.dimValue, menuWidth: menuWidthPoints, offset: calcOffset + menuWidthPoints)
      }
    }
  }

  @ViewBuilder
  private func customLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: StyleParams,
    calcOffset: CGFloat
  ) -> some View {
    if case .custom(_, let sideMenuLayout, let mainViewLayout) = configuration.menuStyle {
      let context = CustomLayoutContext(
        screenWidth: screenWidth,
        menuWidth: menuWidthPoints,
        offset: calcOffset,
        progress: model.calculateProgress(menuWidth: menuWidthPoints),
        isOpen: model.isOpen,
        isDragging: isMenuDragging
      )

      ZStack(alignment: .leading) {
        sideMenuLayout(context, AnyView(sideMenu.frame(width: menuWidthPoints)))
        mainViewLayout(context, AnyView(mainView.frame(width: screenWidth)))
        dimOverlay(dimValue: styleParams.dimValue, menuWidth: menuWidthPoints, offset: calcOffset)
      }
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
  private func dimOverlay(dimValue: CGFloat, menuWidth: CGFloat, offset: CGFloat) -> some View {
    Color.clear
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(
        Color.black.opacity(
          Double(model.calculateProgress(menuWidth: menuWidth) * dimValue)
        )
      )
      .offset(x: offset, y: 0)
      .allowsHitTesting(isMenuOpen)
      .onTapGesture {
        if model.isOpen {
          withAnimation(configuration.menuAnimation) { model.close() }
        }
      }
      .simultaneousGesture(
        createDragGesture(menuWidth: menuWidth, dragParams: extractDragParams())
      )
      .accessibilityLabel("Close menu")
      .accessibilityHint("Double tap to close the side menu")
  }

  @ViewBuilder
  private func sideMenuView(width: CGFloat, offset: CGFloat) -> some View {
    sideMenu
      .frame(width: width)
      .offset(x: offset, y: 0)
      .simultaneousGesture(
        createDragGesture(menuWidth: width, dragParams: extractDragParams()),
        including: isMenuOpen ? .all : .subviews
      )
      .accessibilityFocused($focusTarget, equals: .menu)
      .accessibilityHidden(!isMenuOpen)
      .accessibilityAddTraits(isMenuOpen ? .isModal : [])
  }
}

#Preview {
  
  @Previewable @State var model = SideMenuState()
  
  SideMenuView(
    model: model,
    configuration: .init(menuStyle: .slideOut(scale: 0.8, dimValue: 0.5, backgroundColor: .secondarySystemBackground))
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
