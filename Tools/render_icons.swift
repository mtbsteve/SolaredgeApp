#!/usr/bin/env swift
//
// Renders the SolarEdge app icon (red lightning bolt on white) to
// the iOS and watchOS Assets.xcassets/AppIcon.appiconset folders.
//
// Run from the project root:
//   swift Tools/render_icons.swift
//

import AppKit
import CoreGraphics

let project = FileManager.default.currentDirectoryPath

func renderIcon(to outPath: String, size: Int = 1024) throws {
    let s = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    ) else {
        throw NSError(domain: "render", code: 1, userInfo: [NSLocalizedDescriptionKey: "CGContext failed"])
    }

    // White background (no alpha — App Store rejects icons with transparency).
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

    // Red lightning bolt — 7-point polygon, normalized then scaled.
    // CG y-origin is bottom-left, so we flip y by `s - y`.
    let red = CGColor(red: 0.85, green: 0.10, blue: 0.13, alpha: 1)
    ctx.setFillColor(red)
    let p = CGMutablePath()
    let pts: [(CGFloat, CGFloat)] = [
        (0.55, 0.08),  // top-left of upper bar
        (0.72, 0.08),  // top-right
        (0.50, 0.46),  // mid-right (inner)
        (0.74, 0.46),  // mid-right (outer)
        (0.30, 0.92),  // bottom point
        (0.46, 0.56),  // mid-left (inner)
        (0.22, 0.56),  // mid-left (outer)
    ]
    p.move(to: CGPoint(x: pts[0].0 * s, y: s - pts[0].1 * s))
    for pt in pts.dropFirst() {
        p.addLine(to: CGPoint(x: pt.0 * s, y: s - pt.1 * s))
    }
    p.closeSubpath()
    ctx.addPath(p)
    ctx.fillPath()

    guard let cgImg = ctx.makeImage() else {
        throw NSError(domain: "render", code: 2, userInfo: [NSLocalizedDescriptionKey: "makeImage failed"])
    }
    let rep = NSBitmapImageRep(cgImage: cgImg)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "render", code: 3, userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"])
    }
    let url = URL(fileURLWithPath: outPath)
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try png.write(to: url)
    print("wrote \(outPath)")
}

do {
    try renderIcon(to: "\(project)/iOS/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
    try renderIcon(to: "\(project)/Watch/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
