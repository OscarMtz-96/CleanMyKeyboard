import Foundation

public struct ExitShortcutTracker {
    public let requiredHold: TimeInterval
    private var startedAt: TimeInterval?

    public init(requiredHold: TimeInterval = 2) {
        self.requiredHold = requiredHold
    }

    public mutating func update(isPressed: Bool, now: TimeInterval) -> Bool {
        guard isPressed else {
            startedAt = nil
            return false
        }

        if startedAt == nil {
            startedAt = now
        }

        return now - (startedAt ?? now) >= requiredHold
    }

    public mutating func reset() {
        startedAt = nil
    }
}
