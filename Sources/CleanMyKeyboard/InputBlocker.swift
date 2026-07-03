import CoreGraphics
import Foundation
import KeyboardBlockerCore

final class InputBlocker {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var shortcut = ExitShortcutTracker()
    private var onUnlock: (() -> Void)?

    func start(onUnlock: @escaping () -> Void) -> Bool {
        stop()
        self.onUnlock = onUnlock
        shortcut.reset()

        let systemDefined = CGEventType(rawValue: 14)!
        let events: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged, systemDefined,
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged,
            .scrollWheel, .otherMouseDown, .otherMouseUp, .otherMouseDragged
        ]
        let mask = events.reduce(0) { $0 | (1 << $1.rawValue) }

        let ref = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: eventTapCallback,
            userInfo: ref
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
        onUnlock = nil
        shortcut.reset()
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return nil
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let isExitShortcut =
            keyCode == 53 &&
            flags.contains(.maskControl) &&
            flags.contains(.maskAlternate) &&
            flags.contains(.maskCommand)

        if shortcut.update(isPressed: isExitShortcut, now: ProcessInfo.processInfo.systemUptime) {
            onUnlock?()
        }

        return nil
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return nil }
    let blocker = Unmanaged<InputBlocker>.fromOpaque(userInfo).takeUnretainedValue()
    return blocker.handle(type: type, event: event)
}
