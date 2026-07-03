#!/usr/bin/env swift
import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "dist/dmg-root/.background/dmg-background.png")
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)

let width = 520
let height = 300
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
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

NSColor.clear.setFill()
CGRect(x: 0, y: 0, width: width, height: height).fill()

let arrow = NSBezierPath()
arrow.move(to: CGPoint(x: 220, y: 156))
arrow.line(to: CGPoint(x: 300, y: 156))
arrow.move(to: CGPoint(x: 276, y: 132))
arrow.line(to: CGPoint(x: 304, y: 156))
arrow.line(to: CGPoint(x: 276, y: 180))
NSColor(calibratedWhite: 0.55, alpha: 0.75).setStroke()
arrow.lineWidth = 9
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.stroke()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 0.8),
    .paragraphStyle: paragraph
]
"Drag to Applications".draw(in: CGRect(x: 190, y: 188, width: 150, height: 22), withAttributes: attrs)

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: output)
