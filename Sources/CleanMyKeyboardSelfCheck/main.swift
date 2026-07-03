import KeyboardBlockerCore

var tracker = ExitShortcutTracker(requiredHold: 2)

assert(tracker.update(isPressed: true, now: 10) == false)
assert(tracker.update(isPressed: true, now: 11.9) == false)
assert(tracker.update(isPressed: true, now: 12) == true)

tracker.reset()
assert(tracker.update(isPressed: true, now: 20) == false)
assert(tracker.update(isPressed: false, now: 21) == false)
assert(tracker.update(isPressed: true, now: 22.9) == false)

print("CleanMyKeyboardSelfCheck passed")
