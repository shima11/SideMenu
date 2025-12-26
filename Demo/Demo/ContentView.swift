
import SwiftUI
import SideMenu

struct ContentView: View {
  @State private var menuState = SideMenuState()
  @State private var selectedRoom: String = "Room 1"
  @State private var configuration = SideMenuConfiguration()
  @State private var showDetail = false
  
  private let rooms = ["Room 1", "Room 2", "Room 3", "Room 4", "Room 5"]
  
  var body: some View {
    SideMenuView(
      model: menuState,
      configuration: configuration
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
          Section("Rooms") {
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
          
          Section("Settings") {
            Picker("Menu Style", selection: $configuration.menuStyle) {
              Text("Slide In Over").tag(MenuStyle.slideInOver)
              Text("Slide In Out").tag(MenuStyle.slideInOut)
            }
            
            Picker("Drag Activation", selection: $configuration.dragActivation) {
              Text("Full Screen").tag(MenuDragActivation.full)
              Text("Edge Only").tag(MenuDragActivation.edge)
            }

            Picker("Gesture Handling", selection: $configuration.gestureHandling) {
              Text("Simultaneous").tag(MenuGestureHandling.simultaneous)
              Text("Priority").tag(MenuGestureHandling.highPriority)
              Text("Exclusive").tag(MenuGestureHandling.exclusive)
            }
            
            Toggle("Haptic Feedback", isOn: $configuration.enableHaptics)
            
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Menu Width")
                Spacer()
                Text("\(Int(configuration.menuWidth * 100))%")
                  .foregroundStyle(.secondary)
              }
              Slider(value: $configuration.menuWidth.asDouble(), in: 0.5...0.9, step: 0.05)
            }
            
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Blur Effect")
                Spacer()
                Text(configuration.blur, format: .number.precision(.fractionLength(1)))
                  .foregroundStyle(.secondary)
              }
              Slider(value: $configuration.blur.asDouble(), in: 0...10, step: 0.5)
            }
            
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Dim Opacity")
                Spacer()
                Text(configuration.dimValue, format: .number.precision(.fractionLength(2)))
                  .foregroundStyle(.secondary)
              }
              Slider(value: $configuration.dimValue.asDouble(), in: 0...0.6, step: 0.05)
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
