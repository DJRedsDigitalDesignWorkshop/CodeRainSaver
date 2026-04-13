import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: apply_bundle_icon.swift <bundle-path> <icon-image-path>\n", stderr)
    exit(1)
}

let bundlePath = CommandLine.arguments[1]
let iconPath = CommandLine.arguments[2]

guard let image = NSImage(contentsOfFile: iconPath) else {
    fputs("Could not load icon image at \(iconPath)\n", stderr)
    exit(1)
}

guard NSWorkspace.shared.setIcon(image, forFile: bundlePath, options: []) else {
    fputs("Failed to apply custom icon to \(bundlePath)\n", stderr)
    exit(1)
}
