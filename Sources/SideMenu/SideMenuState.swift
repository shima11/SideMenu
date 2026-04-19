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
    /// Minimum width value to prevent division by zero
    static let minimumWidth: CGFloat = 1.0
  }

  // MARK: - Public Properties

  /// The current state of the menu (for logic/accessibility).
  public private(set) var currentState: State = .closed

  /// Single source of truth for visual offset.
  /// Range: -menuWidth (closed) → 0 (open).
  public var currentOffset: CGFloat = 0

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

  // MARK: - Animation Calculations

  /// Calculates the animation progress (0.0 to 1.0) based on currentOffset.
  ///
  /// - Parameter menuWidth: The width of the menu
  /// - Returns: The progress value from 0.0 (closed) to 1.0 (open)
  public func calculateProgress(menuWidth: CGFloat) -> CGFloat {
    let w = max(menuWidth, AnimationConstants.minimumWidth)
    let progress = (currentOffset + w) / w  // -menuWidth→0, 0→1
    return min(max(progress, 0), 1)
  }

  /// Calculates the scale effect for the main view based on progress.
  /// - Parameters:
  ///   - minScale: Target scale when menu is fully open (0.0 to 1.0)
  ///   - menuWidth: The width of the menu
  /// - Returns: The calculated scale value
  public func calculateScale(minScale: CGFloat, menuWidth: CGFloat) -> CGFloat {
    let progress = calculateProgress(menuWidth: menuWidth)
    return 1.0 - (1.0 - minScale) * progress
  }

  /// Calculates the scale effect for the side menu based on progress.
  /// - Parameters:
  ///   - minScale: The minimum scale when menu is closed (e.g., 0.9)
  ///   - menuWidth: The width of the menu
  /// - Returns: The calculated scale value
  public func calculateMenuScale(minScale: CGFloat, menuWidth: CGFloat) -> CGFloat {
    let progress = calculateProgress(menuWidth: menuWidth)
    return minScale + (1.0 - minScale) * progress
  }

  /// Calculates the blur effect for the main view based on progress.
  /// - Parameters:
  ///   - maxValue: Maximum blur radius when menu is fully open
  ///   - menuWidth: The width of the menu
  /// - Returns: The calculated blur radius
  public func calculateBlur(maxValue: CGFloat, menuWidth: CGFloat) -> CGFloat {
    let progress = calculateProgress(menuWidth: menuWidth)
    return maxValue * progress
  }

  // MARK: - Haptic Threshold Tracking

  /// Whether the drag has passed the 50% snap threshold (for one-shot haptic).
  public var hasPassedThreshold: Bool = false

  // MARK: - Rubber Band

  /// Apple-style rubber band formula: logarithmic resistance beyond a limit.
  /// - Parameters:
  ///   - offset: Actual drag distance beyond the boundary
  ///   - limit: Maximum visual displacement (e.g. 40pt)
  ///   - coefficient: Resistance strength (0.55 = Apple default)
  /// - Returns: Rubber-banded offset value
  internal static func rubberBand(offset: CGFloat, limit: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
    let clamped = max(offset, 0)
    return (1 - (1 / (clamped * coefficient / limit + 1))) * limit
  }
}
