
import Observation
import SwiftUI

// MARK: - State

/// Manages the presentation state of a dual-edge side menu.
///
/// Unlike `SideMenuState`, this state guarantees that **at most one** menu can
/// be open at any time. The exclusion is encoded in the `State` enum itself, so
/// calls like `openLeading()` and `openTrailing()` automatically replace any
/// other open side.
@Observable
public final class DualSideMenuState {

  // MARK: - Constants

  private enum Constants {
    static let minimumWidth: CGFloat = 1.0
  }

  // MARK: - Types

  /// Represents the menu's presentation state.
  public enum State: Equatable {
    /// Both menus are hidden.
    case closed
    /// One menu is presented from the given edge.
    case open(MenuEdge)
  }

  // MARK: - Public Properties

  /// The current state of the menu pair.
  public private(set) var currentState: State = .closed

  /// The current drag offset in points (raw `translation.width`).
  ///
  /// Sign convention: **positive values move toward the leading edge**
  /// (i.e., dragging right in LTR), negative values toward the trailing edge.
  /// The value is constrained based on `currentState` so that it can never
  /// exceed the valid drag range for the current state.
  public private(set) var dragOffset: Float = 0.0

  /// `true` when either menu is fully open.
  public var isOpen: Bool {
    if case .open = currentState { return true }
    return false
  }

  /// The currently open edge, or `nil` if `currentState == .closed`.
  public var openEdge: MenuEdge? {
    if case .open(let edge) = currentState { return edge }
    return nil
  }

  /// Whether the drag has passed the snap threshold (used for one-shot haptic).
  public var hasPassedThreshold: Bool = false

  // MARK: - Initialization

  public init() {}

  // MARK: - Public Methods

  /// Closes both menus.
  public func close() { currentState = .closed }

  /// Opens the leading menu, replacing any other open side.
  public func openLeading() { currentState = .open(.leading) }

  /// Opens the trailing menu, replacing any other open side.
  public func openTrailing() { currentState = .open(.trailing) }

  /// Toggles the menu for `edge`. If the same edge is already open it closes;
  /// otherwise it opens that edge (closing the opposite side if needed).
  public func toggle(_ edge: MenuEdge) {
    if openEdge == edge {
      currentState = .closed
    } else {
      currentState = .open(edge)
    }
  }

  /// Updates the drag offset during gesture interactions.
  public func setDragOffset(_ value: Float) { dragOffset = value }

  /// Resets the drag offset to zero.
  public func resetDragOffset() { dragOffset = 0 }

  // MARK: - Animation Calculations

  /// Signed progress in `[-1, 1]`.
  ///
  /// `+1` = leading menu fully open, `0` = closed, `-1` = trailing menu fully
  /// open. Combines `currentState` with the live `dragOffset`.
  public func calculateSignedProgress(menuWidth: CGFloat) -> CGFloat {
    let normalizedWidth = max(menuWidth, Constants.minimumWidth)
    let dragNormalized = CGFloat(dragOffset) / normalizedWidth
    let stateBase: CGFloat
    switch currentState {
    case .closed: stateBase = 0
    case .open(.leading): stateBase = 1
    case .open(.trailing): stateBase = -1
    }
    return min(1, max(-1, stateBase + dragNormalized))
  }

  /// Absolute progress in `[0, 1]` (0 = closed, 1 = either side fully open).
  public func calculateProgress(menuWidth: CGFloat) -> CGFloat {
    abs(calculateSignedProgress(menuWidth: menuWidth))
  }

  /// Calculates the scale effect applied to the main view.
  ///
  /// Mirrors `SideMenuState.calculateScale` semantics — main shrinks toward
  /// `minScale` as either side opens.
  public func calculateMainScale(minScale: CGFloat) -> CGFloat {
    let progress = calculateProgress(menuWidth: 1)  // already in [0,1]
    return 1 - (1 - minScale) * progress
  }

  /// Calculates the blur radius applied to the main view.
  public func calculateMainBlur(maxValue: CGFloat) -> CGFloat {
    let progress = calculateProgress(menuWidth: 1)
    return maxValue * progress
  }

  /// Calculates the scale of one side menu (only the open side scales up).
  ///
  /// - Parameters:
  ///   - edge: which menu to compute the scale for.
  ///   - minScale: scale value when that side is fully closed/hidden.
  /// - Returns: scale value where `minScale` = that side hidden, `1` = visible.
  public func calculateMenuScale(edge: MenuEdge, minScale: CGFloat) -> CGFloat {
    let signed = calculateSignedProgress(menuWidth: 1)
    let sideProgress: CGFloat
    switch edge {
    case .leading: sideProgress = max(signed, 0)   // 0..1
    case .trailing: sideProgress = max(-signed, 0)
    }
    return minScale + (1 - minScale) * sideProgress
  }
}

// MARK: - Configuration

/// Configuration options for `DualSideMenuView`.
///
/// Mirrors `SideMenuConfiguration` but omits the `edge` field — both edges are
/// always rendered in dual mode.
public struct DualSideMenuConfiguration: Equatable, Sendable {

  /// Width of each menu as a fraction of the screen width (0.0 to 1.0).
  public var menuWidth: CGFloat

  /// Visual presentation style. Shared by both menus.
  ///
  /// - Note: `.custom` is **not** fully supported in dual mode — it falls back
  ///   to `.slideInOver` rendering since the custom layout closures are
  ///   defined for a single-edge context.
  public var menuStyle: MenuStyle

  /// Animation curve used for menu transitions.
  public var menuAnimation: Animation

  /// Controls which screen area can initiate a drag to open a menu.
  ///
  /// In `.edge` mode each side has its own activation zone (leading edge opens
  /// leading, trailing edge opens trailing).
  public var dragActivation: MenuDragActivation

  /// The style of impact haptic feedback when opening or closing via gesture.
  public var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle?

  /// Minimum flick velocity (pt/s) to trigger open/close regardless of distance.
  public var velocityThreshold: CGFloat

  /// Maximum visual displacement for rubber band effect at menu edges.
  public var rubberBandLimit: CGFloat

  public init(
    menuWidth: CGFloat = 0.8,
    menuStyle: MenuStyle = .slideInOut(),
    menuAnimation: Animation = .spring(duration: 0.4, bounce: 0.0),
    dragActivation: MenuDragActivation = .full(),
    hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .medium,
    velocityThreshold: CGFloat = 300,
    rubberBandLimit: CGFloat = 40
  ) {
    self.menuWidth = min(max(menuWidth, 0), 1)
    self.menuStyle = menuStyle
    self.menuAnimation = menuAnimation
    self.dragActivation = dragActivation
    self.hapticStyle = hapticStyle
    self.velocityThreshold = max(velocityThreshold, 0)
    self.rubberBandLimit = max(rubberBandLimit, 0)
  }
}

// MARK: - View

private enum DualMenuLayoutConstants {
  static let minimumWidth: CGFloat = 1
}

/// A side menu component that supports menus on **both** the leading and
/// trailing edges with type-level mutual exclusion.
///
/// Example:
/// ```swift
/// @State private var state = DualSideMenuState()
///
/// DualSideMenuView(
///   model: state,
///   configuration: .init(menuStyle: .slideInOut())
/// ) {
///   LeadingMenu()
/// } trailingMenu: {
///   TrailingMenu()
/// } mainView: {
///   ContentView()
/// }
/// ```
public struct DualSideMenuView<LeadingMenu: View, TrailingMenu: View, MainView: View>: View {

  // MARK: - Public Properties

  public let leadingMenu: LeadingMenu
  public let trailingMenu: TrailingMenu
  public let mainView: MainView
  public let configuration: DualSideMenuConfiguration

  @Bindable public var model: DualSideMenuState

  // MARK: - Private Properties

  @AccessibilityFocusState private var focusTarget: FocusTarget?
  @State private var isMenuDragging = false
  @State private var dragSide: MenuEdge?
  @State private var hapticGenerator: UIImpactFeedbackGenerator?
  @State private var lightHapticGenerator: UIImpactFeedbackGenerator?

  private enum FocusTarget: Hashable {
    case leading
    case trailing
    case main
  }

  // MARK: - Initialization

  @inlinable public init(
    model: DualSideMenuState = .init(),
    configuration: DualSideMenuConfiguration = .init(),
    @ViewBuilder leadingMenu: () -> LeadingMenu,
    @ViewBuilder trailingMenu: () -> TrailingMenu,
    @ViewBuilder mainView: () -> MainView
  ) {
    self.model = model
    self.leadingMenu = leadingMenu()
    self.trailingMenu = trailingMenu()
    self.mainView = mainView()
    self.configuration = configuration
  }

  // MARK: - Body

  public var body: some View {
    GeometryReader { proxy in
      menuContent(screenWidth: max(proxy.size.width, DualMenuLayoutConstants.minimumWidth))
        .frame(width: proxy.size.width, height: proxy.size.height)
        .clipped()
    }
  }

  // MARK: - Computed Helpers

  private struct DragParams {
    let isEdgeOnly: Bool
    let edgeWidth: CGFloat
    let startThreshold: CGFloat
    let openCloseThreshold: CGFloat
    let directionRatio: CGFloat
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

  private enum StyleKind { case slideInOver, slideInOut, slideOut }

  private struct StyleParams {
    let kind: StyleKind
    let blur: CGFloat
    let scale: CGFloat
    let dimValue: CGFloat
    let backgroundColor: UIColor?
  }

  private func extractStyleParams() -> StyleParams {
    switch configuration.menuStyle {
    case .slideInOver(let blur, let scale, let dim):
      return StyleParams(
        kind: .slideInOver,
        blur: max(blur, 0),
        scale: min(max(scale, 0), 1),
        dimValue: min(max(dim, 0), 1),
        backgroundColor: nil
      )
    case .slideInOut(let dim):
      return StyleParams(
        kind: .slideInOut,
        blur: 0,
        scale: 1,
        dimValue: min(max(dim, 0), 1),
        backgroundColor: nil
      )
    case .slideOut(let scale, let dim, let bg):
      return StyleParams(
        kind: .slideOut,
        blur: 0,
        scale: min(max(scale, 0), 1),
        dimValue: min(max(dim, 0), 1),
        backgroundColor: bg
      )
    case .custom(let dim, _, _):
      // Custom layouts cannot express a dual-edge layout — fall back to
      // slideInOver as a reasonable default.
      return StyleParams(
        kind: .slideInOver,
        blur: 0,
        scale: 1,
        dimValue: min(max(dim, 0), 1),
        backgroundColor: nil
      )
    }
  }

  // MARK: - Layout

  @ViewBuilder
  private func menuContent(screenWidth: CGFloat) -> some View {
    let menuWidthPoints = screenWidth * configuration.menuWidth
    let dragParams = extractDragParams()
    let styleParams = extractStyleParams()

    ZStack {
      switch styleParams.kind {
      case .slideInOver:
        slideInOverLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams
        )
      case .slideInOut:
        slideInOutLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams
        )
      case .slideOut:
        slideOutLayout(
          screenWidth: screenWidth,
          menuWidthPoints: menuWidthPoints,
          styleParams: styleParams
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .simultaneousGesture(
      createDragGesture(menuWidth: menuWidthPoints, screenWidth: screenWidth, dragParams: dragParams),
      // Active when (a) closed in full-screen mode (open from anywhere), or
      // (b) any side is open (drag-to-close from anywhere). Disabled only when
      // closed + edge-only — that case is handled by the per-edge overlays.
      including: (model.isOpen || !dragParams.isEdgeOnly) ? .all : .none
    )
    .overlay(alignment: .leading) {
      if dragParams.isEdgeOnly && !model.isOpen {
        Color.clear
          .frame(width: dragParams.edgeWidth)
          .frame(maxHeight: .infinity)
          .contentShape(Rectangle())
          .gesture(createDragGesture(menuWidth: menuWidthPoints, screenWidth: screenWidth, dragParams: dragParams))
      }
    }
    .overlay(alignment: .trailing) {
      if dragParams.isEdgeOnly && !model.isOpen {
        Color.clear
          .frame(width: dragParams.edgeWidth)
          .frame(maxHeight: .infinity)
          .contentShape(Rectangle())
          .gesture(createDragGesture(menuWidth: menuWidthPoints, screenWidth: screenWidth, dragParams: dragParams))
      }
    }
    .accessibilityAction(.escape, closeMenuWithAnimation)
    .accessibilityAction(named: "Close Menu", closeMenuWithAnimation)
    .onChange(of: model.currentState) { _, newValue in
      switch newValue {
      case .open(.leading): focusTarget = .leading
      case .open(.trailing): focusTarget = .trailing
      case .closed: focusTarget = .main
      }
    }
    .onAppear { updateHapticGenerator() }
    .onChange(of: configuration.hapticStyle) { _, _ in updateHapticGenerator() }
    .onDisappear {
      hapticGenerator = nil
      lightHapticGenerator = nil
    }
  }

  private func closeMenuWithAnimation() {
    guard model.isOpen else { return }
    withAnimation(configuration.menuAnimation) { model.close() }
  }

  private func updateHapticGenerator() {
    if let style = configuration.hapticStyle {
      hapticGenerator = UIImpactFeedbackGenerator(style: style)
      hapticGenerator?.prepare()
      lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
      lightHapticGenerator?.prepare()
    } else {
      hapticGenerator = nil
      lightHapticGenerator = nil
    }
  }

  // MARK: - slideInOver

  @ViewBuilder
  private func slideInOverLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: StyleParams
  ) -> some View {
    let signed = model.calculateSignedProgress(menuWidth: menuWidthPoints)
    let absProgress = abs(signed)

    // Menu offsets in raw pixel direction.
    // Leading menu range: -menuWidth (closed/right-open) → 0 (leading-open)
    // Trailing menu range: +menuWidth (closed/leading-open) → 0 (trailing-open)
    let leadingOffset = -menuWidthPoints * (1 - max(signed, 0))
    let trailingOffset = menuWidthPoints * (1 - max(-signed, 0))

    ZStack {
      // Main view, static, with optional blur/scale.
      mainView
        .disabled(isMenuDragging)
        .blur(radius: styleParams.blur * absProgress)
        .scaleEffect(1 - (1 - styleParams.scale) * absProgress)
        .frame(width: screenWidth)
        .accessibilityFocused($focusTarget, equals: .main)
        .accessibilityHidden(model.isOpen)

      // Dim
      dimOverlay(dimValue: styleParams.dimValue, progress: absProgress)

      // Leading menu, anchored to leading edge
      menuContainer(view: leadingMenu, edge: .leading, width: menuWidthPoints, offset: min(leadingOffset, 0))

      // Trailing menu, anchored to trailing edge
      menuContainer(view: trailingMenu, edge: .trailing, width: menuWidthPoints, offset: max(trailingOffset, 0))
    }
  }

  // MARK: - slideInOut

  @ViewBuilder
  private func slideInOutLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: StyleParams
  ) -> some View {
    let signed = model.calculateSignedProgress(menuWidth: menuWidthPoints)
    let absProgress = abs(signed)

    // Per-element offsets so the layout stays within the screen frame
    // (no HStack overflow). All three views translate by the same amount, so
    // visually they appear to "slide together".
    //
    // - main natural position: centered → x ∈ [0, screenWidth]
    // - leading natural position: anchored leading → x ∈ [0, menuWidth]
    //   (offset by -menuWidth places it off-screen left in closed state)
    // - trailing natural position: anchored trailing → x ∈ [screenWidth-menuWidth, screenWidth]
    //   (offset by +menuWidth places it off-screen right in closed state)
    let mainShift = signed * menuWidthPoints
    let leadingShift = -menuWidthPoints + mainShift
    let trailingShift = menuWidthPoints + mainShift

    ZStack {
      // Leading menu — anchored to leading edge, off-screen left when closed.
      leadingMenu
        .frame(width: menuWidthPoints)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .offset(x: leadingShift)
        .accessibilityFocused($focusTarget, equals: .leading)
        .accessibilityHidden(model.openEdge != .leading)

      // Trailing menu — anchored to trailing edge, off-screen right when closed.
      trailingMenu
        .frame(width: menuWidthPoints)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .offset(x: trailingShift)
        .accessibilityFocused($focusTarget, equals: .trailing)
        .accessibilityHidden(model.openEdge != .trailing)

      // Main + dim — slides together with the menus.
      mainView
        .disabled(isMenuDragging)
        .blur(radius: styleParams.blur * absProgress)
        .scaleEffect(1 - (1 - styleParams.scale) * absProgress)
        .frame(width: screenWidth)
        .overlay {
          Color.black
            .opacity(Double(absProgress * styleParams.dimValue))
            .allowsHitTesting(model.isOpen)
            .onTapGesture { closeMenuWithAnimation() }
        }
        .offset(x: mainShift)
        .accessibilityFocused($focusTarget, equals: .main)
        .accessibilityHidden(model.isOpen)
    }
  }

  // MARK: - slideOut

  @ViewBuilder
  private func slideOutLayout(
    screenWidth: CGFloat,
    menuWidthPoints: CGFloat,
    styleParams: StyleParams
  ) -> some View {
    let signed = model.calculateSignedProgress(menuWidth: menuWidthPoints)
    let absProgress = abs(signed)

    ZStack {
      // Optional background panels behind each side
      if let bg = styleParams.backgroundColor {
        HStack {
          Color(uiColor: bg).frame(width: menuWidthPoints)
          Spacer(minLength: 0)
          Color(uiColor: bg).frame(width: menuWidthPoints)
        }
        .ignoresSafeArea()
      }

      // Leading menu fixed at leading edge with scale anchored to its trailing side
      menuContainer(view: leadingMenu, edge: .leading, width: menuWidthPoints, offset: 0)
        .scaleEffect(
          model.calculateMenuScale(edge: .leading, minScale: styleParams.scale),
          anchor: .trailing
        )

      // Trailing menu fixed at trailing edge with scale anchored to its leading side
      menuContainer(view: trailingMenu, edge: .trailing, width: menuWidthPoints, offset: 0)
        .scaleEffect(
          model.calculateMenuScale(edge: .trailing, minScale: styleParams.scale),
          anchor: .leading
        )

      // Main + dim slide together
      ZStack {
        mainView
          .disabled(isMenuDragging)
          .frame(width: screenWidth)
          .accessibilityFocused($focusTarget, equals: .main)
          .accessibilityHidden(model.isOpen)

        Color.black
          .opacity(Double(absProgress * styleParams.dimValue))
          .allowsHitTesting(model.isOpen)
          .onTapGesture { closeMenuWithAnimation() }
      }
      .offset(x: signed * menuWidthPoints)
    }
  }

  // MARK: - Shared helpers

  @ViewBuilder
  private func dimOverlay(dimValue: CGFloat, progress: CGFloat) -> some View {
    Color.black
      .opacity(Double(progress * dimValue))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .allowsHitTesting(model.isOpen)
      .onTapGesture { closeMenuWithAnimation() }
      .accessibilityLabel("Close menu")
      .accessibilityHint("Double tap to close the side menu")
  }

  @ViewBuilder
  private func menuContainer<V: View>(view: V, edge: MenuEdge, width: CGFloat, offset: CGFloat) -> some View {
    view
      .frame(width: width)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: edge == .leading ? .leading : .trailing
      )
      .offset(x: offset, y: 0)
      .accessibilityFocused($focusTarget, equals: edge == .leading ? .leading : .trailing)
      .accessibilityHidden(model.openEdge != edge)
      .accessibilityAddTraits(model.openEdge == edge ? .isModal : [])
  }

  // MARK: - Drag

  private func createDragGesture(
    menuWidth: CGFloat,
    screenWidth: CGFloat,
    dragParams: DragParams
  ) -> some Gesture {
    DragGesture(minimumDistance: dragParams.startThreshold)
      .onChanged { value in
        handleDragChanged(value: value, menuWidth: menuWidth, screenWidth: screenWidth, dragParams: dragParams)
      }
      .onEnded { value in
        handleDragEnded(value: value, menuWidth: menuWidth, screenWidth: screenWidth, dragParams: dragParams)
      }
  }

  /// Returns the valid `dragOffset` range given current state and the (optional)
  /// committed side. The return convention matches `dragOffset`'s sign:
  /// positive = toward leading-open direction.
  private func validDragRange(menuWidth: CGFloat, committedSide: MenuEdge?) -> ClosedRange<CGFloat> {
    switch model.currentState {
    case .closed:
      switch committedSide {
      case .leading: return 0...menuWidth
      case .trailing: return -menuWidth...0
      case .none: return -menuWidth...menuWidth
      }
    case .open(.leading):
      // Dragging closes leading: translation goes from 0 (open) to -menuWidth (closed).
      return -menuWidth...0
    case .open(.trailing):
      // Dragging closes trailing: translation goes from 0 (open) to +menuWidth (closed).
      return 0...menuWidth
    }
  }

  private func handleDragChanged(
    value: DragGesture.Value,
    menuWidth: CGFloat,
    screenWidth: CGFloat,
    dragParams: DragParams
  ) {
    let horizontal = abs(value.translation.width)
    let vertical = abs(value.translation.height)
    let translation = value.translation.width

    // Horizontal-vs-vertical gate
    guard horizontal > vertical * dragParams.directionRatio else {
      isMenuDragging = false
      return
    }

    if horizontal > dragParams.startThreshold && !isMenuDragging {
      isMenuDragging = true
    }
    guard isMenuDragging else { return }

    // Determine which side this drag is interacting with.
    var committedSide: MenuEdge? = dragSide
    if model.currentState == .closed && committedSide == nil {
      if dragParams.isEdgeOnly {
        // Edge-only: side determined by drag start zone, plus matching direction.
        let startsLeading = value.startLocation.x <= dragParams.edgeWidth
        let startsTrailing = value.startLocation.x >= screenWidth - dragParams.edgeWidth
        if startsLeading && translation > 0 {
          committedSide = .leading
        } else if startsTrailing && translation < 0 {
          committedSide = .trailing
        } else {
          // Drag did not start in a valid edge zone, or wrong direction — bail out.
          isMenuDragging = false
          return
        }
      } else {
        // Full-screen mode: direction commits the side.
        if translation > 0 {
          committedSide = .leading
        } else if translation < 0 {
          committedSide = .trailing
        }
      }
      dragSide = committedSide
    }

    // Clamp translation to the valid range for the current state/side.
    let range = validDragRange(menuWidth: menuWidth, committedSide: committedSide)
    let clamped = min(max(translation, range.lowerBound), range.upperBound)

    withTransaction(Transaction(animation: nil)) {
      model.setDragOffset(Float(clamped))
    }

    // Threshold haptic — fired once when crossing 50% of menu width while opening.
    if configuration.hapticStyle != nil, model.currentState == .closed, let side = committedSide {
      let progressTowardOpen: CGFloat
      switch side {
      case .leading: progressTowardOpen = clamped / menuWidth
      case .trailing: progressTowardOpen = -clamped / menuWidth
      }
      let pastThreshold = progressTowardOpen > 0.5
      if pastThreshold != model.hasPassedThreshold {
        model.hasPassedThreshold = pastThreshold
        lightHapticGenerator?.impactOccurred()
      }
    }
  }

  private func handleDragEnded(
    value: DragGesture.Value,
    menuWidth: CGFloat,
    screenWidth: CGFloat,
    dragParams: DragParams
  ) {
    let translation = value.translation.width
    let velocityX = value.velocity.width
    let startingState = model.currentState
    let committedSide = dragSide

    if !isMenuDragging {
      withTransaction(Transaction(animation: configuration.menuAnimation)) {
        model.resetDragOffset()
        dragSide = nil
      }
      return
    }

    isMenuDragging = false
    model.hasPassedThreshold = false

    // Compute final progress decision.
    let range = validDragRange(menuWidth: menuWidth, committedSide: committedSide)
    let clamped = min(max(translation, range.lowerBound), range.upperBound)

    let stateBase: CGFloat
    switch startingState {
    case .closed: stateBase = 0
    case .open(.leading): stateBase = 1
    case .open(.trailing): stateBase = -1
    }
    let currentProgress = stateBase + clamped / menuWidth  // signed [-1, +1]

    // Snap target progress.
    let targetProgress: CGFloat
    let isFlick = abs(velocityX) > configuration.velocityThreshold
    switch startingState {
    case .closed:
      // Choose between -1, 0, +1
      if isFlick {
        if velocityX > 0 && currentProgress > 0 { targetProgress = 1 }
        else if velocityX < 0 && currentProgress < 0 { targetProgress = -1 }
        else { targetProgress = 0 }
      } else {
        if currentProgress > 0.5 { targetProgress = 1 }
        else if currentProgress < -0.5 { targetProgress = -1 }
        else { targetProgress = 0 }
      }
    case .open(.leading):
      // currentProgress in [0, 1]. Target: 0 or 1.
      if isFlick {
        targetProgress = velocityX > 0 ? 1 : 0
      } else {
        targetProgress = currentProgress > 0.5 ? 1 : 0
      }
    case .open(.trailing):
      // currentProgress in [-1, 0]. Target: -1 or 0.
      if isFlick {
        targetProgress = velocityX < 0 ? -1 : 0
      } else {
        targetProgress = currentProgress < -0.5 ? -1 : 0
      }
    }

    // Build interpolating-spring with initial velocity matching the gesture.
    let remainingPixels = (targetProgress - currentProgress) * menuWidth
    let normalizedVelocity: Double
    if abs(remainingPixels) > 1 {
      normalizedVelocity = velocityX / remainingPixels
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
      dragSide = nil
      if targetProgress >= 1 { model.openLeading() }
      else if targetProgress <= -1 { model.openTrailing() }
      else { model.close() }
    }

    // Haptic on state change
    let endedAt: DualSideMenuState.State = targetProgress >= 1
      ? .open(.leading)
      : (targetProgress <= -1 ? .open(.trailing) : .closed)
    if endedAt != startingState {
      hapticGenerator?.impactOccurred()
    }
  }
}

// MARK: - Previews

private struct DualSideMenuPreviewHost: View {
  let style: MenuStyle
  let initialState: DualSideMenuState.State

  @State private var model = DualSideMenuState()

  init(style: MenuStyle, initialState: DualSideMenuState.State = .closed) {
    self.style = style
    self.initialState = initialState
  }

  var body: some View {
    DualSideMenuView(
      model: model,
      configuration: .init(menuStyle: style)
    ) {
      List {
        Section("Leading") {
          Button("Home") { withAnimation { model.close() } }
          Button("Settings") { withAnimation { model.close() } }
        }
      }
    } trailingMenu: {
      List {
        Section("Trailing") {
          Button("Filters") { withAnimation { model.close() } }
          Button("Sort") { withAnimation { model.close() } }
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
        .navigationTitle("Dual")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              withAnimation { model.toggle(.leading) }
            } label: { Image(systemName: "line.3.horizontal") }
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              withAnimation { model.toggle(.trailing) }
            } label: { Image(systemName: "slider.horizontal.3") }
          }
        }
      }
    }
    .onAppear {
      switch initialState {
      case .closed: break
      case .open(.leading): model.openLeading()
      case .open(.trailing): model.openTrailing()
      }
    }
  }
}

#Preview("Dual · slideInOut · Closed") {
  DualSideMenuPreviewHost(style: .slideInOut(dimValue: 0.3))
}

#Preview("Dual · slideInOut · Leading") {
  DualSideMenuPreviewHost(style: .slideInOut(dimValue: 0.3), initialState: .open(.leading))
}

#Preview("Dual · slideInOut · Trailing") {
  DualSideMenuPreviewHost(style: .slideInOut(dimValue: 0.3), initialState: .open(.trailing))
}

#Preview("Dual · slideInOver · Leading") {
  DualSideMenuPreviewHost(
    style: .slideInOver(blur: 3, scale: 0.95, dimValue: 0.3),
    initialState: .open(.leading)
  )
}

#Preview("Dual · slideInOver · Trailing") {
  DualSideMenuPreviewHost(
    style: .slideInOver(blur: 3, scale: 0.95, dimValue: 0.3),
    initialState: .open(.trailing)
  )
}

#Preview("Dual · slideOut · Leading") {
  DualSideMenuPreviewHost(
    style: .slideOut(scale: 0.85, dimValue: 0.4, backgroundColor: .secondarySystemBackground),
    initialState: .open(.leading)
  )
}

#Preview("Dual · slideOut · Trailing") {
  DualSideMenuPreviewHost(
    style: .slideOut(scale: 0.85, dimValue: 0.4, backgroundColor: .secondarySystemBackground),
    initialState: .open(.trailing)
  )
}
