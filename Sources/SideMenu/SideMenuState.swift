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

    /// Minimum width value to prevent division by zero
    static let minimumWidth: CGFloat = 1.0
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

  /// Calculates normalized progress based on current drag state and width.
  /// - Parameters:
  ///   - totalWidth: The total width of the screen
  ///   - dampingFactor: Factor to adjust the sensitivity of the calculation
  /// - Returns: The normalized progress value
  private func calculateNormalizedProgress(totalWidth: CGFloat, dampingFactor: CGFloat) -> CGFloat {
    let normalizedWidth = max(totalWidth, AnimationConstants.minimumWidth) / dampingFactor
    return CGFloat(dragOffset) / normalizedWidth
  }

  /// Calculates the scale effect for the main view based on drag progress.
  /// - Parameters:
  ///   - minScale: Target scale when menu is fully open (0.0 to 1.0)
  ///   - totalWidth: The total width of the screen
  /// - Returns: The calculated scale value
  public func calculateScale(minScale: CGFloat, totalWidth: CGFloat) -> CGFloat {
    let progress = calculateNormalizedProgress(
      totalWidth: totalWidth,
      dampingFactor: AnimationConstants.scaleDampingFactor
    )

    let defaultScale: CGFloat = 1.0
    let targetScale: CGFloat = minScale

    if progress == 0 {
      return currentState == .open ? targetScale : defaultScale
    }

    if currentState == .open {
      if dragOffset > 0 {
        return targetScale
      } else {
        return min(targetScale + abs(progress), defaultScale)
      }
    } else {
      if dragOffset > 0 {
        return max(defaultScale - abs(progress), targetScale)
      } else {
        return defaultScale
      }
    }
  }

  /// Calculates the scale effect for the side menu based on drag progress.
  /// Unlike `calculateScale`, this starts small when closed and grows to 1.0 when open.
  /// - Parameters:
  ///   - minScale: The minimum scale when menu is closed (e.g., 0.9)
  ///   - menuWidth: The width of the menu
  /// - Returns: The calculated scale value
  public func calculateMenuScale(minScale: CGFloat, menuWidth: CGFloat) -> CGFloat {
    let progress = calculateProgress(menuWidth: menuWidth)
    // progress: 0 (closed) -> 1 (open)
    // scale: minScale (closed) -> 1.0 (open)
    return minScale + (1.0 - minScale) * progress
  }

  /// Calculates the blur effect for the main view based on drag progress.
  /// - Parameters:
  ///   - maxValue: Maximum blur radius when menu is fully open
  ///   - totalWidth: The total width of the screen
  /// - Returns: The calculated blur radius
  public func calculateBlur(maxValue: CGFloat, totalWidth: CGFloat) -> CGFloat {
    let progress = calculateNormalizedProgress(
      totalWidth: totalWidth,
      dampingFactor: AnimationConstants.blurDampingFactor
    ) * maxValue

    let maxBlur: CGFloat = maxValue
    let minBlur: CGFloat = 0

    if progress == 0 {
      return currentState == .open ? maxBlur : minBlur
    }

    if currentState == .open {
      if dragOffset > 0 {
        return maxBlur
      } else {
        return max(maxBlur - abs(progress), minBlur)
      }
    } else {
      if dragOffset > 0 {
        return min(minBlur + abs(progress), maxBlur)
      } else {
        return minBlur
      }
    }
  }

  /// Calculates the animation progress (0.0 to 1.0) based on drag state.
  ///
  /// This method is designed for calculating opacity and other linear progress values,
  /// providing a normalized progress value from 0.0 (closed) to 1.0 (open).
  ///
  /// - Parameter menuWidth: The width of the menu
  /// - Returns: The progress value from 0.0 (closed) to 1.0 (open)
  public func calculateProgress(menuWidth: CGFloat) -> CGFloat {
    let normalizedWidth = max(menuWidth, AnimationConstants.minimumWidth)
    let progress = CGFloat(dragOffset) / normalizedWidth

    if currentState == .open {
      // When menu is open, keep dimming at maximum unless dragging to close
      if dragOffset >= 0 {
        return 1.0
      } else {
        let value = 1.0 + progress  // progress is negative when dragging left
        return max(value, 0.0)
      }
    } else {
      // When menu is closed, dimming increases as menu opens
      if dragOffset > 0 {
        let value = progress
        return min(value, 1.0)
      } else {
        return 0.0
      }
    }
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
