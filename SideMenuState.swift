import Observation
import SwiftUI

/// Manages the presentation state of the side menu.
///
/// This observable class tracks the menu's open/closed state and drag gestures,
/// calculating visual effects like blur and scale during transitions.
@Observable
public final class SideMenuState {

  // MARK: - Constants

  private enum AnimationConstants {
    /// Damping factor for scale animation (higher = slower transition)
    static let scaleDampingFactor: CGFloat = 4.0

    /// Damping factor for blur animation (higher = faster transition)
    static let blurDampingFactor: CGFloat = 4.0

    /// Resistance when dragging past menu edge
    static let edgeBounceResistance: Float = 2.0
  }

  // MARK: - Public Properties

  /// The current state of the menu.
  public private(set) var currentState: State = .closed

  /// The current drag offset in points.
  public private(set) var dragOffset: Float = 0.0

  /// Whether the menu is currently open.
  public var isOpen: Bool { currentState == .open }

  // MARK: - Types

  /// Represents the menu's presentation state.
  public enum State {
    /// Menu is visible
    case open
    /// Menu is hidden
    case closed
  }

  // MARK: - Initialization

  public init() {}

  // MARK: - Public Methods

  /// Toggles between open and closed states.
  public func toggle() {
    currentState = (currentState == .open) ? .closed : .open
  }

  /// Opens the menu.
  public func open() {
    currentState = .open
  }

  /// Closes the menu.
  public func close() {
    currentState = .closed
  }

  /// Updates the drag offset during gesture interactions.
  /// - Parameter value: The drag offset in points.
  public func setDragOffset(_ value: Float) {
    dragOffset = value
  }

  /// Resets the drag offset to zero.
  public func resetDragOffset() {
    dragOffset = 0
  }

  // MARK: - Animation Calculations

  /// Calculates the scale effect for the main view based on drag progress.
  /// - Parameters:
  ///   - minScale: Target scale when menu is fully open (0.0 to 1.0)
  ///   - totalWidth: The total width of the screen
  /// - Returns: The calculated scale value
  public func calculateScale(minScale: CGFloat, totalWidth: CGFloat) -> CGFloat {
    let normalizedWidth = max(totalWidth, 1) * AnimationConstants.scaleDampingFactor
    let currentWidth = self.dragOffset

    let defaultScale: CGFloat = 1.0
    let targetScale: CGFloat = minScale

    let scaleProgress = CGFloat(currentWidth) * defaultScale / normalizedWidth

    if scaleProgress == 0 {
      return currentState == .open ? targetScale : defaultScale
    }

    if currentState == .open {
      if dragOffset > 0 {
        return targetScale
      } else {
        let scale = targetScale + abs(scaleProgress)
        return min(scale, defaultScale)
      }
    } else {
      if dragOffset > 0 {
        let scale = defaultScale - abs(scaleProgress)
        return max(scale, targetScale)
      } else {
        return defaultScale
      }
    }
  }

  /// Calculates the blur effect for the main view based on drag progress.
  /// - Parameters:
  ///   - maxValue: Maximum blur radius when menu is fully open
  ///   - totalWidth: The total width of the screen
  /// - Returns: The calculated blur radius
  public func calculateBlur(maxValue: CGFloat, totalWidth: CGFloat) -> CGFloat {
    let normalizedWidth = max(totalWidth, 1) / AnimationConstants.blurDampingFactor
    let currentWidth = self.dragOffset

    let maxBlur: CGFloat = maxValue
    let minBlur: CGFloat = 0

    let blurProgress = CGFloat(currentWidth) * maxValue / normalizedWidth

    if blurProgress == 0 {
      return currentState == .open ? maxBlur : minBlur
    }

    if currentState == .open {
      if dragOffset > 0 {
        return maxBlur
      } else {
        let blur = maxBlur - abs(blurProgress)
        return max(blur, minBlur)
      }
    } else {
      if dragOffset > 0 {
        let blur = minBlur + abs(blurProgress)
        return min(blur, maxBlur)
      } else {
        return minBlur
      }
    }
  }

  /// Returns the edge bounce resistance value.
  internal static var edgeBounceResistance: Float {
    AnimationConstants.edgeBounceResistance
  }
}
