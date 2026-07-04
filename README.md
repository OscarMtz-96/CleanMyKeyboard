# Clean My Keyboard

Minimal macOS app to block keyboard and mouse input while you clean your MacBook.

Download the latest DMG installer from [Releases](https://github.com/OscarMtz-96/CleanMyKeyboard/releases/latest).

Unlock shortcut: hold `Control + Option + Command + Escape` for 2 seconds.

## Run from source

```sh
swift run CleanMyKeyboard
```

macOS will ask for Accessibility permission. Without it, global input blocking cannot work.

## Build a DMG

```sh
./scripts/package-dmg.sh
```

The installer is published as a `.dmg` in Releases.
Open it and drag `Clean My Keyboard.app` into `Applications`.

## Notes

- The app uses native Swift, SwiftUI/AppKit, and CoreGraphics.
- No dependencies, no Electron.
- Function/media keys are handled through macOS `systemDefined` events when macOS exposes them to the event tap.
- Some hardware/system buttons may still bypass apps because macOS does not let third-party apps intercept everything.
