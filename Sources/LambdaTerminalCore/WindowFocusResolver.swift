import Foundation

/// Resolves which window receives menu commands (new tab, open in project).
public enum WindowFocusResolver {
    /// Returns the focused window when valid; otherwise the sole window; otherwise last as bootstrap only.
    public static func commandTarget(
        focusedWindowID: UUID?,
        windows: [WindowSessionBundle]
    ) -> UUID? {
        if let focused = focusedWindowID,
           windows.contains(where: { $0.id == focused }) {
            return focused
        }
        if windows.count == 1 {
            return windows.first?.id
        }
        return windows.last?.id
    }
}
