// Renders Resources/AppIcon.icns and Resources/MenuBarIcon.png from Resources/Brand/logo.png and ICON.png.
// Run from the repo root: `swift scripts/make-icon.swift`.
import AppKit

func load(_ path: String) -> CGImage {
    let image = NSImage(contentsOfFile: path)!
    return image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
}

/// The equalizer bars, without the wordmark (top-left origin, in source pixels).
func bars(_ image: CGImage) -> CGImage {
    let scale = CGFloat(image.width) / 1254
    return image.cropping(to: CGRect(x: 165 * scale, y: 305 * scale, width: 925 * scale, height: 435 * scale))!
}

func png(_ cg: CGImage, size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.current?.cgContext.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// MARK: App icon

let size: CGFloat = 1024
let icon = NSImage(size: NSSize(width: size, height: size))
icon.lockFocus()
let rect = NSRect(x: 100, y: 100, width: 824, height: 824)
let squircle = NSBezierPath(roundedRect: rect, xRadius: 186, yRadius: 186)

NSGraphicsContext.current?.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
NSColor.black.setFill()
squircle.fill()
NSGraphicsContext.current?.restoreGraphicsState()

squircle.addClip()
NSGradient(colors: [
    NSColor(red: 0.07, green: 0.09, blue: 0.16, alpha: 1),
    NSColor(red: 0.11, green: 0.14, blue: 0.25, alpha: 1),
])!.draw(in: rect, angle: -90)
// Soft blue glow and a glass sheen.
NSGradient(colors: [NSColor(red: 0.1, green: 0.6, blue: 1, alpha: 0.35), NSColor.clear])!
    .draw(fromCenter: NSPoint(x: 512, y: 470), radius: 0, toCenter: NSPoint(x: 512, y: 470), radius: 420, options: [])
NSGradient(colors: [NSColor.white.withAlphaComponent(0.14), NSColor.white.withAlphaComponent(0)])!
    .draw(in: NSRect(x: 100, y: 512, width: 824, height: 412), angle: -90)

let logo = bars(load("Resources/Brand/logo.png"))
let barWidth: CGFloat = 600
let barHeight = barWidth * CGFloat(logo.height) / CGFloat(logo.width)
NSGraphicsContext.current?.cgContext.draw(logo, in: CGRect(x: 512 - barWidth / 2, y: 512 - barHeight / 2, width: barWidth, height: barHeight))
icon.unlockFocus()

let fm = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)
let cg = icon.cgImage(forProposedRect: nil, context: nil, hints: nil)!
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! png(cg, size: base * scale).write(to: iconset.appendingPathComponent(name))
    }
}
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
try! png(cg, size: 1024).write(to: URL(fileURLWithPath: "Resources/AppIcon.png"))

// MARK: Menu bar template icon (18pt tall, @2x)

let mark = bars(load("Resources/Brand/ICON.png"))
let height = 30
let width = Int((CGFloat(height) * CGFloat(mark.width) / CGFloat(mark.height)).rounded())
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current?.imageInterpolation = .high
NSGraphicsContext.current?.cgContext.draw(mark, in: CGRect(x: 0, y: 0, width: width, height: height))
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Resources/MenuBarIcon.png"))
print("Wrote Resources/AppIcon.icns, AppIcon.png, MenuBarIcon.png")

// MARK: Horizontal brand (footer + README)

/// The "soniq" wordmark, without the bars.
func wordmark(_ image: CGImage) -> CGImage {
    let scale = CGFloat(image.width) / 1254
    return image.cropping(to: CGRect(x: 165 * scale, y: 742 * scale, width: 925 * scale, height: 355 * scale))!
}

func save(_ cg: CGImage, height: Int, to path: String, tint: NSColor? = nil) {
    let width = Int((CGFloat(height) * CGFloat(cg.width) / CGFloat(cg.height)).rounded())
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.interpolationQuality = .high
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
    if let tint {
        ctx.setBlendMode(.sourceIn)
        ctx.setFillColor(tint.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let colorLogo = load("Resources/Brand/logo.png")
let barsImage = bars(colorLogo)
let wordImage = wordmark(colorLogo)
save(barsImage, height: 40, to: "Resources/BrandMark.png")
save(wordImage, height: 40, to: "Resources/Wordmark.png", tint: .white)

/// Bars and wordmark side by side for the README, in white (dark theme) and near-black (light theme).
func horizontal(text: NSColor, to path: String) {
    let barH: CGFloat = 160
    let barW = barH * CGFloat(barsImage.width) / CGFloat(barsImage.height)
    let wordH: CGFloat = 150
    let wordW = wordH * CGFloat(wordImage.width) / CGFloat(wordImage.height)
    let gap: CGFloat = 48
    // The wordmark baseline sits 23% above the bottom of its crop (the "q" descender).
    let descender = wordH * 0.23
    let size = NSSize(width: barW + gap + wordW, height: barH + descender)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.interpolationQuality = .high
    ctx.draw(barsImage, in: CGRect(x: 0, y: descender, width: barW, height: barH))
    // Tint the wordmark in its own layer so the bars keep their colors.
    let wordRect = CGRect(x: barW + gap, y: 0, width: wordW, height: wordH)
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.draw(wordImage, in: wordRect)
    ctx.setBlendMode(.sourceIn)
    ctx.setFillColor(text.cgColor)
    ctx.fill(wordRect)
    ctx.endTransparencyLayer()
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
horizontal(text: .white, to: "docs/logo-dark.png")
horizontal(text: NSColor(white: 0.11, alpha: 1), to: "docs/logo-light.png")
print("Wrote BrandMark.png, Wordmark.png, docs/logo-dark.png, docs/logo-light.png")
