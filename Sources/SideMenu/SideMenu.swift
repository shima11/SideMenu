
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

      // Extract drag activation parameters
      let dragParams: (isEdgeOnly: Bool, edgeWidth: CGFloat, startThreshold: CGFloat, openCloseThreshold: CGFloat) = {
        switch configuration.dragActivation {
        case .edge(let edgeWidth, let startThreshold, let openCloseThreshold):
          return (true, max(edgeWidth, 0), max(startThreshold, 0), max(openCloseThreshold, 0))
        case .full(let startThreshold, let openCloseThreshold):
          return (false, 0, max(startThreshold, 0), max(openCloseThreshold, 0))
        }
      }()

      let dragGesture = DragGesture()
        .onChanged { value in
          let horizontal = abs(value.translation.width)
          let vertical = abs(value.translation.height)
          let isEdgeOnly = dragParams.isEdgeOnly
          let isOpeningFromEdge = isEdgeOnly && !isMenuOpen && value.startLocation.x > dragParams.edgeWidth

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
          if horizontal > dragParams.startThreshold && !isMenuDragging {
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
          let isEdgeOnly = dragParams.isEdgeOnly
          let isOpeningFromEdge = isEdgeOnly && !isMenuOpen && value.startLocation.x > dragParams.edgeWidth
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

          let didClose = startingState == .open && shouldClose
          let didOpen = startingState == .closed && shouldOpen
          if didClose || didOpen {
            hapticGenerator?.impactOccurred()
          }
        }

      // Calculate offset (currently only supports leading edge)
      let baseOffset = -(menuWidthPoints * CGFloat(model.currentState == .open ? 0 : 1))
      let calcOffset = baseOffset + CGFloat(model.dragOffset)

      // Extract style-specific parameters
      let styleParams: (isSlideInOver: Bool, blur: CGFloat, scale: CGFloat, dimValue: CGFloat) = {
        switch configuration.menuStyle {
        case .slideInOver(let blur, let scale, let dimValue):
          return (true, max(blur, 0), min(max(scale, 0), 1), min(max(dimValue, 0), 1))
        case .slideInOut(let dimValue):
          return (false, 0, 1, min(max(dimValue, 0), 1))
        }
      }()

      HStack (spacing: 0) {
        if styleParams.isSlideInOver {
          ZStack(alignment: .leading) {
            mainView
              .blur(radius: model.calculateBlur(maxValue: styleParams.blur, totalWidth: screenWidth))
              .scaleEffect(model.calculateScale(minScale: styleParams.scale, totalWidth: screenWidth))
              .frame(width: screenWidth)
              .disabled(isMenuDragging)
              .allowsHitTesting(!isMenuDragging)
              .accessibilityFocused($focusTarget, equals: .main)
              .accessibilityHidden(isMenuOpen)

            Color.clear
              .frame(maxWidth: .infinity,  maxHeight: .infinity)
              .overlay(Color.black.opacity(Double(model.calculateBlur(maxValue: styleParams.dimValue, totalWidth: screenWidth))))
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
                .overlay(Color.black.opacity(Double(model.calculateBlur(maxValue: styleParams.dimValue, totalWidth: screenWidth))))
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

  // Style-specific parameters
  @State private var blur: Double = 2
  @State private var scale: Double = 1
  @State private var dimValue: Double = 0.2

  // Drag activation parameters
  @State private var edgeWidth: Double = 24
  @State private var startThreshold: Double = 6
  @State private var openCloseThreshold: Double = 50

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

  private var menuStyle: SideMenu.MenuStyle {
    switch configuration.menuStyle {
    case .slideInOver:
      return .slideInOver(blur: blur, scale: scale, dimValue: dimValue)
    case .slideInOut:
      return .slideInOut(dimValue: dimValue)
    }
  }

  private var dragActivation: MenuDragActivation {
    switch configuration.dragActivation {
    case .edge:
      return .edge(edgeWidth: edgeWidth, startThreshold: startThreshold, openCloseThreshold: openCloseThreshold)
    case .full:
      return .full(startThreshold: startThreshold, openCloseThreshold: openCloseThreshold)
    }
  }

  private var isEdgeDragActivation: Bool {
    switch configuration.dragActivation {
    case .edge:
      return true
    case .full:
      return false
    }
  }

  var body: some View {
    SideMenuView(
      model: model,
      configuration: SideMenuConfiguration(
        menuWidth: configuration.menuWidth,
        menuStyle: menuStyle,
        menuAnimation: menuAnimation,
        dragActivation: dragActivation,
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
                Text("Full").tag(MenuDragActivation.full())
                Text("Edge").tag(MenuDragActivation.edge())
              }
              .onChange(of: configuration.dragActivation) { _, newValue in
                switch newValue {
                case .edge(let defaultEdgeWidth, let defaultStartThreshold, let defaultOpenCloseThreshold):
                  edgeWidth = defaultEdgeWidth
                  startThreshold = defaultStartThreshold
                  openCloseThreshold = defaultOpenCloseThreshold
                case .full(let defaultStartThreshold, let defaultOpenCloseThreshold):
                  startThreshold = defaultStartThreshold
                  openCloseThreshold = defaultOpenCloseThreshold
                }
              }
              PreviewValueSlider(
                title: "Edge Width",
                value: $edgeWidth,
                range: 0...80,
                step: 2
              )
              .disabled(!isEdgeDragActivation)
              PreviewValueSlider(
                title: "Drag Start",
                value: $startThreshold,
                range: 0...20,
                step: 1
              )
              PreviewValueSlider(
                title: "Open/Close",
                value: $openCloseThreshold,
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
                Text("Slide In Over").tag(MenuStyle.slideInOver())
                Text("Slide In Out").tag(MenuStyle.slideInOut())
              }
              .onChange(of: configuration.menuStyle) { _, newValue in
                switch newValue {
                case .slideInOver(let defaultBlur, let defaultScale, let defaultDimValue):
                  blur = defaultBlur
                  scale = defaultScale
                  dimValue = defaultDimValue
                case .slideInOut(let defaultDimValue):
                  dimValue = defaultDimValue
                }
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
                value: $blur,
                range: 0...10,
                step: 0.5
              )
              PreviewValueSlider(
                title: "Scale",
                value: $scale,
                range: 0.8...1.0,
                step: 0.02
              )
              PreviewValueSlider(
                title: "Dim",
                value: $dimValue,
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
