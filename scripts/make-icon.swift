#!/usr/bin/env swift
import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "dist/AppIcon.iconset")
try? FileManager.default.removeItem(at: output)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: 1
    )
}

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high

    let scale = size / 1024
    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale)
    }
    func radius(_ value: CGFloat) -> CGFloat { value * scale }

    NSColor.clear.setFill()
    CGRect(x: 0, y: 0, width: size, height: size).fill()

    color(0xF5F7FA).setFill()
    NSBezierPath(roundedRect: rect(96, 172, 832, 600), xRadius: radius(96), yRadius: radius(96)).fill()
    color(0xC9D3DE).setStroke()
    let body = NSBezierPath(roundedRect: rect(96, 172, 832, 600), xRadius: radius(96), yRadius: radius(96))
    body.lineWidth = 28 * scale
    body.stroke()

    color(0xDCE4EC).setFill()
    for row in 0..<3 {
        for col in 0..<10 {
            let x = 176 + CGFloat(col) * 68
            let y = 300 + CGFloat(row) * 82
            NSBezierPath(roundedRect: rect(x, y, 46, 38), xRadius: radius(9), yRadius: radius(9)).fill()
        }
    }
    NSBezierPath(roundedRect: rect(304, 222, 416, 42), xRadius: radius(14), yRadius: radius(14)).fill()

    color(0x111827).setStroke()
    let shackle = NSBezierPath()
    shackle.lineWidth = 46 * scale
    shackle.lineCapStyle = .round
    shackle.appendArc(
        withCenter: CGPoint(x: 512 * scale, y: 610 * scale),
        radius: 135 * scale,
        startAngle: 0,
        endAngle: 180
    )
    shackle.stroke()

    color(0x111827).setFill()
    NSBezierPath(roundedRect: rect(348, 396, 328, 246), xRadius: radius(58), yRadius: radius(58)).fill()
    color(0xFFFFFF).setFill()
    NSBezierPath(ovalIn: rect(486, 498, 52, 52)).fill()
    NSBezierPath(roundedRect: rect(501, 448, 22, 70), xRadius: radius(11), yRadius: radius(11)).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for (name, size) in sizes {
    let data = drawIcon(size: size).representation(using: .png, properties: [:])!
    try data.write(to: output.appendingPathComponent(name))
}
