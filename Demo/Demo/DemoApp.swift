
import SwiftUI

@main
struct DemoApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

enum DemoMode: String, CaseIterable, Identifiable {
  case single = "Single"
  case dual = "Dual"
  var id: Self { self }
}

struct RootView: View {
  @State private var mode: DemoMode = .single

  var body: some View {
    switch mode {
    case .single: ContentView(mode: $mode)
    case .dual: DualContentView(mode: $mode)
    }
  }
}
