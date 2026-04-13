import AppKit
import Foundation

let outputRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = outputRoot.appendingPathComponent("Resources/CodeRainSaver.iconset", isDirectory: true)
let glyphs = ["ｱ", "ｲ", "ｳ", "ｴ", "ｵ", "ｶ", "ｷ", "ｸ", "ｹ", "ｺ", "ｻ", "ｼ", "ｽ", "ｾ", "ｿ", "ﾀ", "ﾁ", "ﾂ", "ﾃ", "ﾄ", "ﾅ", "ﾆ", "ﾇ", "ﾈ", "ﾉ", "ﾏ", "ﾐ", "ﾑ", "ﾒ", "ﾓ", "ﾔ", "ﾕ", "ﾖ", "ﾗ", "ﾘ", "ﾙ", "ﾚ", "ﾛ", "ﾜ", "ﾝ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

let fm = FileManager.default
try? fm.removeItem(at: iconsetURL)
try fm.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let variants: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

func makeImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else { return image }
    context.interpolationQuality = .high
    context.setAllowsAntialiasing(true)

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let corner = size * 0.225
    let clipPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04), xRadius: corner, yRadius: corner)
    clipPath.addClip()

    let bg = NSGradient(colors: [
        NSColor(calibratedRed: 0.0, green: 0.01, blue: 0.005, alpha: 1.0),
        NSColor(calibratedRed: 0.01, green: 0.05, blue: 0.02, alpha: 1.0)
    ])!
    bg.draw(in: clipPath, angle: 90)

    let glowRect = CGRect(x: size * 0.18, y: size * 0.16, width: size * 0.64, height: size * 0.68)
    let glow = NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.52, blue: 0.18, alpha: 0.45),
        NSColor(calibratedRed: 0.0, green: 0.25, blue: 0.08, alpha: 0.0)
    ])!
    glow.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: .zero)

    let stripeCount = max(6, Int(size / 22))
    for index in 0..<stripeCount {
        let x = size * 0.10 + CGFloat(index) * (size * 0.8 / CGFloat(stripeCount))
        let alpha = 0.06 + CGFloat(index % 3) * 0.02
        NSColor(calibratedRed: 0.0, green: 0.28, blue: 0.10, alpha: alpha).setFill()
        CGRect(x: x, y: size * 0.06, width: 1, height: size * 0.88).fill()
    }

    let columnCount = max(7, Int(size / 32))
    let fontSize = size * 0.105
    let font = NSFont(name: "HiraginoSans-W3", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    let headFont = NSFont(name: "HiraginoSans-W6", size: fontSize * 1.02) ?? NSFont.monospacedSystemFont(ofSize: fontSize * 1.02, weight: .medium)

    for column in 0..<columnCount {
        let x = size * 0.12 + CGFloat(column) * (size * 0.76 / CGFloat(columnCount - 1))
        let topOffset = CGFloat((column * 7) % 13) * size * 0.018
        let length = 5 + (column % 5)
        let headIndex = 1 + (column % 3)

        for row in 0..<length {
            let glyph = glyphs[(column * 5 + row * 3) % glyphs.count]
            let y = size * 0.82 - CGFloat(row) * (fontSize * 0.9) - topOffset
            let isHead = row == headIndex
            let color: NSColor
            let drawFont: NSFont

            if isHead {
                color = NSColor(calibratedRed: 0.84, green: 0.98, blue: 0.84, alpha: 0.96)
                drawFont = headFont
            } else if row < headIndex {
                color = NSColor(calibratedRed: 0.40, green: 0.96, blue: 0.44, alpha: 0.82)
                drawFont = font
            } else {
                let fade = max(0.18, 1.0 - CGFloat(row) / CGFloat(length + 1))
                color = NSColor(calibratedRed: 0.05, green: 0.82, blue: 0.18, alpha: fade * 0.75)
                drawFont = font
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .font: drawFont,
                .foregroundColor: color
            ]
            glyph.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }

    let accentPath = NSBezierPath()
    accentPath.lineCapStyle = .round
    accentPath.lineJoinStyle = .round
    accentPath.lineWidth = max(2, size * 0.018)
    accentPath.move(to: CGPoint(x: size * 0.32, y: size * 0.34))
    accentPath.line(to: CGPoint(x: size * 0.44, y: size * 0.58))
    accentPath.line(to: CGPoint(x: size * 0.52, y: size * 0.44))
    accentPath.line(to: CGPoint(x: size * 0.64, y: size * 0.70))
    NSColor(calibratedRed: 0.65, green: 1.0, blue: 0.68, alpha: 0.28).setStroke()
    accentPath.stroke()

    let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04), xRadius: corner, yRadius: corner)
    borderPath.lineWidth = max(1, size * 0.01)
    NSColor(calibratedRed: 0.2, green: 0.85, blue: 0.28, alpha: 0.18).setStroke()
    borderPath.stroke()

    return image
}

for (pixels, filename) in variants {
    let image = makeImage(size: CGFloat(pixels))
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "CodeRainSaverIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode \(filename)"])
    }

    try pngData.write(to: iconsetURL.appendingPathComponent(filename))
}

print("Generated iconset at \(iconsetURL.path)")
