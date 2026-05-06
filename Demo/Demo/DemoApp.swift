
import SwiftUI

@main
struct DemoApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

struct RootView: View {
  enum Mode: String, CaseIterable, Identifiable {
    case single = "Single"
    case dual = "Dual"
    var id: Self { self }
  }

  @State private var mode: Mode = .single

  var body: some View {
    ZStack {
      switch mode {
      case .single: ContentView()
      case .dual: DualContentView()
      }
    }
    .safeAreaInset(edge: .bottom) {
      Picker("Mode", selection: $mode) {
        ForEach(Mode.allCases) { mode in
          Text(mode.rawValue).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(.ultraThinMaterial)
    }
  }
}
