
import SwiftUI
import SideMenu

struct ContentView: View {
  @State private var menuState = SideMenuState()
  @State private var selectedRoom: String = "Room 1"
  @State private var configuration = SideMenuConfiguration()
  @State private var showDetail = false
  @State private var showSettings = false
  
  // Style-specific parameters
  @State private var blur: Double = 2
  @State private var scale: Double = 1
  @State private var dimValue: Double = 0.2
  
  // Drag activation parameters
  @State private var edgeWidth: Double = 24
  @State private var startThreshold: Double = 6
  @State private var openCloseThreshold: Double = 50
  
  private let rooms = ["Room 1", "Room 2", "Room 3", "Room 4", "Room 5"]
  
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
  
  var body: some View {
    SideMenuView(
      model: menuState,
      configuration: SideMenuConfiguration(
        menuWidth: configuration.menuWidth,
        menuStyle: menuStyle,
        menuAnimation: configuration.menuAnimation,
        dragActivation: dragActivation,
        hapticStyle: configuration.hapticStyle
      )
    ) {
      // Side Menu Content
      menuContent
    } mainView: {
      // Main Content
      mainContent
    }
  }
  
  private var menuContent: some View {
    ZStack {
      Color(uiColor: .systemBackground)
      
      NavigationStack {
        List {
          ForEach(rooms, id: \.self) { room in
            Button(room) {
              withAnimation(configuration.menuAnimation) {
                selectedRoom = room
                if menuState.isOpen {
                  menuState.close()
                }
              }
            }
          }
        }
        .navigationTitle("Menu")
      }
    }
  }
  
  private var mainContent: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 12) {
          ForEach(0..<20) { index in
            Button {
              showDetail = true
            } label: {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Item \(index + 1)")
                    .font(.headline)
                  Text("Tap to see details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                  .foregroundStyle(.secondary)
              }
              .padding()
              .background(Color(uiColor: .secondarySystemBackground))
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
      }
      .navigationTitle(selectedRoom)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            withAnimation(configuration.menuAnimation) {
              menuState.toggle()
            }
          } label: {
            Image(systemName: "line.3.horizontal")
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showSettings = true
          } label: {
            Image(systemName: "gearshape")
          }
        }
      }
      .sheet(isPresented: $showDetail) {
        NavigationStack {
          VStack {
            Text("Detail View")
              .font(.title)
            Text("This is a demo detail view")
              .foregroundStyle(.secondary)
          }
          .navigationTitle("Details")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              Button("Close") {
                showDetail = false
              }
            }
          }
        }
      }
      .sheet(isPresented: $showSettings) {
        settingsView
      }
    }
  }

  private var settingsView: some View {
    NavigationStack {
      List {
        Section("Menu Style") {
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

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Blur Effect")
              Spacer()
              Text(blur, format: .number.precision(.fractionLength(1)))
                .foregroundStyle(.secondary)
            }
            Slider(value: $blur, in: 0...10, step: 0.5)
          }

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Scale")
              Spacer()
              Text(scale, format: .number.precision(.fractionLength(2)))
                .foregroundStyle(.secondary)
            }
            Slider(value: $scale, in: 0.8...1.0, step: 0.02)
          }

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Dim Opacity")
              Spacer()
              Text(dimValue, format: .number.precision(.fractionLength(2)))
                .foregroundStyle(.secondary)
            }
            Slider(value: $dimValue, in: 0...0.6, step: 0.05)
          }
        }

        Section("Interaction") {
          Picker("Drag Activation", selection: $configuration.dragActivation) {
            Text("Full Screen").tag(MenuDragActivation.full())
            Text("Edge Only").tag(MenuDragActivation.edge())
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

          Picker("Haptic Feedback", selection: $configuration.hapticStyle) {
            Text("None").tag(nil as UIImpactFeedbackGenerator.FeedbackStyle?)
            Text("Light").tag(UIImpactFeedbackGenerator.FeedbackStyle.light as UIImpactFeedbackGenerator.FeedbackStyle?)
            Text("Medium").tag(UIImpactFeedbackGenerator.FeedbackStyle.medium as UIImpactFeedbackGenerator.FeedbackStyle?)
            Text("Heavy").tag(UIImpactFeedbackGenerator.FeedbackStyle.heavy as UIImpactFeedbackGenerator.FeedbackStyle?)
          }

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Menu Width")
              Spacer()
              Text("\(Int(configuration.menuWidth * 100))%")
                .foregroundStyle(.secondary)
            }
            Slider(value: $configuration.menuWidth.asDouble(), in: 0.5...0.9, step: 0.05)
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            showSettings = false
          }
        }
      }
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

#Preview {
  ContentView()
}
