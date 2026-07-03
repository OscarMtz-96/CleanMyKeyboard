import AppKit
import CoreGraphics
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isLocked = false
    @Published var hasAccessibilityPermission = AXIsProcessTrusted()
    var onChange: (() -> Void)?

    private let blocker = InputBlocker()

    func refreshPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }

    func openPrivacySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    func lock() {
        refreshPermission()
        guard hasAccessibilityPermission else {
            requestPermission()
            onChange?()
            return
        }

        isLocked = blocker.start { [weak self] in
            Task { @MainActor in self?.unlock() }
        }
        onChange?()
    }

    func unlock() {
        blocker.stop()
        isLocked = false
        onChange?()
    }
}

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: state.isLocked ? "keyboard.badge.eye" : "keyboard")
                .font(.system(size: 42, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(state.isLocked ? .green : .secondary)

            VStack(spacing: 6) {
                Text(state.isLocked ? "Keyboard Locked" : "Unlocked")
                    .font(.system(size: 28, weight: .semibold))
                Text(state.isLocked ? "Hold Control Option Command Escape for 2 seconds to unlock." : "Block keyboard and mouse while you clean your MacBook.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if state.hasAccessibilityPermission {
                Button(state.isLocked ? "Unlock" : "Lock Inputs") {
                    state.isLocked ? state.unlock() : state.lock()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            } else {
                VStack(spacing: 10) {
                    Text("Accessibility permission is required to block input.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    HStack {
                        Button("Request Permission") { state.requestPermission() }
                        Button("Open Settings") { state.openPrivacySettings() }
                    }
                }
            }
        }
        .padding(32)
        .frame(width: 420)
        .onAppear { state.refreshPermission() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = AppState()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var window: NSWindow?

    func applicationDidFinishLaunching(_: Notification) {
        state.onChange = { [weak self] in self?.updateStatusItem() }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clean My Keyboard"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(state: state))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
        updateStatusItem()
    }

    func applicationWillTerminate(_: Notification) {
        state.unlock()
    }

    private func updateStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: state.isLocked ? "keyboard.badge.eye" : "keyboard",
            accessibilityDescription: "Clean My Keyboard"
        )
        statusItem.button?.image?.isTemplate = true
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: state.isLocked ? "Keyboard Locked" : "Clean My Keyboard", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: state.isLocked ? "Unlock" : "Lock Inputs", action: #selector(toggleLock), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func toggleLock() {
        state.isLocked ? state.unlock() : state.lock()
    }

    @objc private func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
