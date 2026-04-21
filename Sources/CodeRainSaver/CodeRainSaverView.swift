import AppKit
import QuartzCore
import ScreenSaver

@objc(CodeRainSaverView)
class CodeRainSaverView: ScreenSaverView {
    private static let preferencesChangedNotification = Notification.Name("com.justinmarsh.coderainsaver.preferencesChanged")
    private static let preferencesDirectoryName = "CodeRainSaver"
    private static let preferencesFileName = "preferences.plist"

    private enum PreferenceKey: String, CaseIterable {
        case speedMultiplier
        case darkness
        case moire
        case persistence
        case density
        case glow
        case glyphScale

        var title: String {
            switch self {
            case .speedMultiplier: return "Speed"
            case .darkness: return "Darkness"
            case .moire: return "Moire"
            case .persistence: return "Persistence"
            case .density: return "Density"
            case .glow: return "Glow"
            case .glyphScale: return "Glyph Size"
            }
        }

        var range: ClosedRange<Double> {
            switch self {
            case .speedMultiplier: return 0.25...2.2
            case .darkness: return 0.2...1.0
            case .moire: return 0.0...1.0
            case .persistence: return 0.65...4.0
            case .density: return 0.45...2.2
            case .glow: return 0.15...1.4
            case .glyphScale: return 0.7...1.55
            }
        }
    }

    private struct Preferences: Equatable {
        var speedMultiplier: Double
        var darkness: Double
        var moire: Double
        var persistence: Double
        var density: Double
        var glow: Double
        var glyphScale: Double

        init(
            speedMultiplier: Double,
            darkness: Double,
            moire: Double,
            persistence: Double,
            density: Double,
            glow: Double,
            glyphScale: Double
        ) {
            self.speedMultiplier = speedMultiplier
            self.darkness = darkness
            self.moire = moire
            self.persistence = persistence
            self.density = density
            self.glow = glow
            self.glyphScale = glyphScale
        }

        static let standard = Preferences(
            speedMultiplier: 0.48,
            darkness: 0.94,
            moire: 0.92,
            persistence: 3.18,
            density: 1.98,
            glow: 0.66,
            glyphScale: 1.06
        )

        func value(for key: PreferenceKey) -> Double {
            switch key {
            case .speedMultiplier: return speedMultiplier
            case .darkness: return darkness
            case .moire: return moire
            case .persistence: return persistence
            case .density: return density
            case .glow: return glow
            case .glyphScale: return glyphScale
            }
        }

        mutating func setValue(_ value: Double, for key: PreferenceKey) {
            switch key {
            case .speedMultiplier: speedMultiplier = value
            case .darkness: darkness = value
            case .moire: moire = value
            case .persistence: persistence = value
            case .density: density = value
            case .glow: glow = value
            case .glyphScale: glyphScale = value
            }
        }

        func dictionary() -> [String: Any] {
            [
                PreferenceKey.speedMultiplier.rawValue: speedMultiplier,
                PreferenceKey.darkness.rawValue: darkness,
                PreferenceKey.moire.rawValue: moire,
                PreferenceKey.persistence.rawValue: persistence,
                PreferenceKey.density.rawValue: density,
                PreferenceKey.glow.rawValue: glow,
                PreferenceKey.glyphScale.rawValue: glyphScale
            ]
        }

        static func sanitizedValue(_ rawValue: Double, for key: PreferenceKey, fallback: Double) -> Double {
            guard rawValue.isFinite else { return fallback }
            let range = key.range
            return min(max(rawValue, range.lowerBound), range.upperBound)
        }

        func sanitized() -> Preferences {
            var sanitizedPreferences = self
            for key in PreferenceKey.allCases {
                let fallback = Self.standard.value(for: key)
                sanitizedPreferences.setValue(
                    Self.sanitizedValue(value(for: key), for: key, fallback: fallback),
                    for: key
                )
            }
            return sanitizedPreferences
        }

        init(dictionary: [String: Any]) {
            func value(_ key: PreferenceKey, fallback: Double) -> Double {
                if let number = dictionary[key.rawValue] as? NSNumber {
                    return Self.sanitizedValue(number.doubleValue, for: key, fallback: fallback)
                }
                if let value = dictionary[key.rawValue] as? Double {
                    return Self.sanitizedValue(value, for: key, fallback: fallback)
                }
                return fallback
            }

            self.init(
                speedMultiplier: value(.speedMultiplier, fallback: Self.standard.speedMultiplier),
                darkness: value(.darkness, fallback: Self.standard.darkness),
                moire: value(.moire, fallback: Self.standard.moire),
                persistence: value(.persistence, fallback: Self.standard.persistence),
                density: value(.density, fallback: Self.standard.density),
                glow: value(.glow, fallback: Self.standard.glow),
                glyphScale: value(.glyphScale, fallback: Self.standard.glyphScale)
            )
        }
    }

    private struct Column {
        var x: CGFloat
        var headY: CGFloat
        var speed: CGFloat
        var length: Int
        var minHeadY: CGFloat
        var maxHeadY: CGFloat
        var glyphs: [String]
        var glowBoost: CGFloat
        var brightness: CGFloat
        var leadSpan: Int
        var mutationTimer: TimeInterval
        var mutationInterval: TimeInterval
    }

    private enum GlyphStyle: CaseIterable {
        case trail
        case bright
        case brightGlow
        case head
        case headGlow

        var usesHeadFont: Bool {
            switch self {
            case .head, .headGlow:
                true
            case .trail, .bright, .brightGlow:
                false
            }
        }

        func color() -> NSColor {
            switch self {
            case .trail:
                return NSColor(calibratedRed: 0.05, green: 0.84, blue: 0.18, alpha: 1.0)
            case .bright:
                return NSColor(calibratedRed: 0.46, green: 0.96, blue: 0.48, alpha: 1.0)
            case .brightGlow:
                return NSColor(calibratedRed: 0.14, green: 0.7, blue: 0.2, alpha: 1.0)
            case .head:
                return NSColor(calibratedRed: 0.84, green: 0.98, blue: 0.83, alpha: 1.0)
            case .headGlow:
                return NSColor(calibratedRed: 0.46, green: 0.98, blue: 0.45, alpha: 1.0)
            }
        }

        func padding(for pointSize: CGFloat) -> CGSize {
            switch self {
            case .headGlow:
                return CGSize(width: pointSize * 0.28, height: pointSize * 0.22)
            case .brightGlow:
                return CGSize(width: pointSize * 0.12, height: pointSize * 0.08)
            case .trail, .bright, .head:
                return CGSize(width: 0, height: 0)
            }
        }
    }

    private struct GlyphSpriteKey: Hashable {
        let glyph: String
        let style: GlyphStyle
    }

    private struct GlyphSprite {
        let cgImage: CGImage
        let drawOffset: NSPoint
        let size: NSSize
    }

    private final class GlyphSlotLayers {
        let mainLayer: CALayer
        let glowLayer: CALayer
        var mainKey: GlyphSpriteKey?
        var glowKey: GlyphSpriteKey?

        init(contentsScale: CGFloat) {
            self.mainLayer = GlyphSlotLayers.makeLayer(contentsScale: contentsScale)
            self.glowLayer = GlyphSlotLayers.makeLayer(contentsScale: contentsScale)
        }

        func updateContentsScale(_ contentsScale: CGFloat) {
            mainLayer.contentsScale = contentsScale
            glowLayer.contentsScale = contentsScale
        }

        private static func makeLayer(contentsScale: CGFloat) -> CALayer {
            let layer = CALayer()
            layer.anchorPoint = .zero
            layer.contentsScale = contentsScale
            layer.contentsGravity = .resize
            layer.magnificationFilter = .nearest
            layer.minificationFilter = .nearest
            layer.allowsEdgeAntialiasing = false
            layer.isOpaque = false
            layer.isHidden = true
            layer.actions = [
                "position": NSNull(),
                "bounds": NSNull(),
                "contents": NSNull(),
                "opacity": NSNull(),
                "hidden": NSNull(),
                "frame": NSNull()
            ]
            return layer
        }
    }

    private let bundle = Bundle(for: CodeRainSaverView.self)
    private let moduleName = Bundle(for: CodeRainSaverView.self).bundleIdentifier ?? "com.justinmarsh.coderainsaver"
    private let usesCatalinaRenderer = (Bundle(for: CodeRainSaverView.self).bundleIdentifier == "com.justinmarsh.coderaincatalina")
    private let glyphPool = [
        "ｱ", "ｲ", "ｳ", "ｴ", "ｵ", "ｶ", "ｷ", "ｸ", "ｹ", "ｺ",
        "ｻ", "ｼ", "ｽ", "ｾ", "ｿ", "ﾀ", "ﾁ", "ﾂ", "ﾃ", "ﾄ",
        "ﾅ", "ﾆ", "ﾇ", "ﾈ", "ﾉ", "ﾊ", "ﾋ", "ﾌ", "ﾍ", "ﾎ",
        "ﾏ", "ﾐ", "ﾑ", "ﾒ", "ﾓ", "ﾔ", "ﾕ", "ﾖ", "ﾗ", "ﾘ",
        "ﾙ", "ﾚ", "ﾛ", "ﾜ", "ｦ", "ﾝ",
        "ｱ", "ｲ", "ｳ", "ｴ", "ｵ", "ﾗ", "ﾘ", "ﾙ", "ﾚ", "ﾛ",
        "0", "1", "2", "3",
        "4", "5", "6", "7", "8", "9", ":", ".", "=", "+",
        "-", "<", ">", "¦", "|", "｢", "｣"
    ]

    private var preferences = Preferences.standard
    private var columns: [Column] = []
    private var glyphFont = NSFont.monospacedSystemFont(ofSize: 26, weight: .regular)
    private var headGlyphFont = NSFont.monospacedSystemFont(ofSize: 29, weight: .medium)
    private var glyphStep: CGFloat = 30
    private var columnStride: CGFloat = 18
    private var didSetup = false
    private var lastFrameTimestamp: CFTimeInterval = 0
    private var preferencesReloadAccumulator: TimeInterval = 0
    private var glyphSpriteCache: [GlyphSpriteKey: GlyphSprite] = [:]
    private var backgroundImage: CGImage?
    private let backgroundLayer = CALayer()
    private let rainLayer = CALayer()
    private var columnLayerSlots: [[GlyphSlotLayers]] = []

    private var configureSheetWindow: NSWindow?
    private var sliderByKey: [PreferenceKey: NSSlider] = [:]
    private var valueLabelByKey: [PreferenceKey: NSTextField] = [:]
    private lazy var previewControlsButton: NSButton = {
        let button = NSButton(title: "Open Controls", target: self, action: #selector(openPreviewControls))
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.contentTintColor = NSColor(calibratedRed: 0.62, green: 0.96, blue: 0.66, alpha: 1.0)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override var isOpaque: Bool {
        true
    }

    @objc(hasConfigureSheet) override dynamic var hasConfigureSheet: Bool {
        true
    }

    @objc(configureSheet) override dynamic var configureSheet: NSWindow? {
        if configureSheetWindow == nil {
            configureSheetWindow = makeConfigureSheet()
        }
        refreshConfigureSheetControls()
        return configureSheetWindow
    }

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    override func makeBackingLayer() -> CALayer {
        let rootLayer = CALayer()
        rootLayer.backgroundColor = NSColor.black.cgColor
        rootLayer.isOpaque = true
        return rootLayer
    }

    private func sharedInit() {
        animationTimeInterval = 1.0 / 60.0
        loadPreferences()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleExternalPreferencesChange(_:)),
            name: Self.preferencesChangedNotification,
            object: nil
        )
        if !usesCatalinaRenderer {
            wantsLayer = true
            layerContentsRedrawPolicy = .never
        }
        addSubview(previewControlsButton)
        NSLayoutConstraint.activate([
            previewControlsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            previewControlsButton.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        ])
        updatePreviewControlsButtonVisibility()
        if !usesCatalinaRenderer {
            configureLayerTree()
        }
    }

    override func startAnimation() {
        super.startAnimation()
        lastFrameTimestamp = CACurrentMediaTime()
        updatePreviewControlsButtonVisibility()
        if !usesCatalinaRenderer {
            configureLayerTree()
        }
        rebuildColumns()
    }

    override func stopAnimation() {
        super.stopAnimation()
        lastFrameTimestamp = 0
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updatePreviewControlsButtonVisibility()
        if !usesCatalinaRenderer {
            configureLayerTree()
        }
        rebuildColumns()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updatePreviewControlsButtonVisibility()
        if !usesCatalinaRenderer {
            configureLayerTree()
        }
    }

    override func animateOneFrame() {
        guard !columns.isEmpty else {
            if !didSetup {
                rebuildColumns()
            }
            return
        }

        autoreleasepool {
            let now = CACurrentMediaTime()
            let unclampedDelta = lastFrameTimestamp > 0 ? now - lastFrameTimestamp : animationTimeInterval
            lastFrameTimestamp = now

            let deltaTime = CGFloat(unclampedDelta.clamped(to: (1.0 / 120.0)...(1.0 / 24.0)))
            let motionTime = deltaTime * CGFloat(preferences.speedMultiplier)
            preferencesReloadAccumulator += TimeInterval(deltaTime)

            for index in columns.indices {
                columns[index].headY += columns[index].speed * motionTime
                columns[index].mutationTimer -= TimeInterval(deltaTime * (0.55 + CGFloat(preferences.speedMultiplier) * 0.35))

                if columns[index].mutationTimer <= 0 {
                    mutateColumn(at: index)
                    columns[index].mutationTimer = columns[index].mutationInterval
                }

                if columns[index].headY > columns[index].maxHeadY {
                    wrapColumn(at: index)
                }
            }

            if preferencesReloadAccumulator >= 0.5 {
                preferencesReloadAccumulator = 0
                _ = applyExternalPreferencesIfNeeded()
            }
        }

        if usesCatalinaRenderer {
            needsDisplay = true
        } else {
            updateRainLayers()
        }
    }

    override func mouseDown(with event: NSEvent) {
        if shouldShowInlineControls, event.clickCount >= 2 {
            openPreviewControls()
            return
        }

        super.mouseDown(with: event)
    }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        rect.fill()

        guard usesCatalinaRenderer else { return }
        drawCatalinaRain(in: rect)
    }

    private func loadPreferences() {
        preferences = currentPreferencesFromDefaults()
    }

    private func savePreferences() {
        preferences = preferences.sanitized()
        if let defaults = ScreenSaverDefaults(forModuleWithName: moduleName) {
            for (key, value) in preferences.dictionary() {
                defaults.set(value, forKey: key)
            }
            defaults.synchronize()
        }

        writeSharedPreferences(preferences)
        DistributedNotificationCenter.default().post(name: Self.preferencesChangedNotification, object: nil)
    }

    private func currentPreferencesFromDefaults() -> Preferences {
        if let sharedPreferences = readSharedPreferences() {
            return sharedPreferences
        }

        guard let defaults = ScreenSaverDefaults(forModuleWithName: moduleName) else {
            return .standard
        }

        defaults.synchronize()
        defaults.register(defaults: Preferences.standard.dictionary())

        let preferences = Preferences(
            speedMultiplier: defaults.double(forKey: PreferenceKey.speedMultiplier.rawValue),
            darkness: defaults.double(forKey: PreferenceKey.darkness.rawValue),
            moire: defaults.double(forKey: PreferenceKey.moire.rawValue),
            persistence: defaults.double(forKey: PreferenceKey.persistence.rawValue),
            density: defaults.double(forKey: PreferenceKey.density.rawValue),
            glow: defaults.double(forKey: PreferenceKey.glow.rawValue),
            glyphScale: defaults.double(forKey: PreferenceKey.glyphScale.rawValue)
        ).sanitized()
        writeSharedPreferences(preferences)
        return preferences
    }

    @discardableResult
    private func applyExternalPreferencesIfNeeded() -> Bool {
        let latestPreferences = currentPreferencesFromDefaults()
        guard latestPreferences != preferences else { return false }

        preferences = latestPreferences
        refreshConfigureSheetControls()
        rebuildColumns()
        return true
    }

    private func rebuildColumns() {
        didSetup = true
        columns.removeAll(keepingCapacity: true)
        configureLayerTree()

        let minDimension = min(bounds.width, bounds.height)
        let scale = max(0.68, min(1.45, minDimension / 900.0))
        let fontSize = (isPreview ? 16.5 : 21.5) * scale * preferences.glyphScale
        glyphFont = NSFont(name: "HiraginoSans-W5", size: fontSize) ?? NSFont(name: "HiraginoSans-W6", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        headGlyphFont = NSFont(name: "HiraginoSans-W7", size: fontSize * 1.02) ?? NSFont(name: "HiraginoSans-W8", size: fontSize * 1.02) ?? NSFont.monospacedSystemFont(ofSize: fontSize * 1.02, weight: .heavy)
        glyphStep = fontSize * 0.96
        columnStride = max(7, fontSize * 0.58)
        glyphSpriteCache.removeAll(keepingCapacity: true)
        backgroundImage = makeBackgroundImage()

        let baseColumnCount = bounds.width / columnStride
        let desiredColumnCount = max(12, Int(baseColumnCount * preferences.density))
        let minimumColumnSpacing = max(8.4, fontSize * 0.74)
        let maximumNonOverlappingCount = max(12, Int(bounds.width / minimumColumnSpacing))
        let columnCount = min(desiredColumnCount, maximumNonOverlappingCount)
        let spacing = max(minimumColumnSpacing, bounds.width / CGFloat(columnCount))

        for index in 0..<columnCount {
            let x = ((CGFloat(index) + 0.5) * spacing).rounded(.toNearestOrAwayFromZero)
            columns.append(makeColumn(x: x, randomHead: true))
        }

        if usesCatalinaRenderer {
            needsDisplay = true
        } else {
            rebuildRainLayers()
            updateRainLayers()
        }
    }

    private func makeColumn(x: CGFloat, randomHead: Bool) -> Column {
        let baseLength = randomFloat(in: isPreview ? 28...40 : 44...60)
        let length = max(14, Int(baseLength * CGFloat(preferences.persistence)))
        let gapDistance = glyphStep * CGFloat(length) * 0.2
        let minHeadY = -gapDistance
        let maxHeadY = bounds.height + glyphStep * (CGFloat(length) + 1.5)
        let headY = randomHead
            ? randomFloat(in: minHeadY...maxHeadY)
            : randomFloat(in: minHeadY...0)
        let speed = randomFloat(in: isPreview ? 42...88 : 52...112)
        let mutationInterval = Double.random(in: 0.15...0.34) * preferences.persistence
        let glyphs = (0..<length).map { _ in randomGlyph() }

        return Column(
            x: x,
            headY: headY,
            speed: speed,
            length: length,
            minHeadY: minHeadY,
            maxHeadY: maxHeadY,
            glyphs: glyphs,
            glowBoost: randomFloat(in: 0.85...1.25),
            brightness: randomFloat(in: 0.88...1.08),
            leadSpan: Int.random(in: 3...5),
            mutationTimer: mutationInterval,
            mutationInterval: mutationInterval
        )
    }

    private func wrapColumn(at index: Int) {
        var column = columns[index]
        let cycleDistance = column.maxHeadY - column.minHeadY
        while column.headY > column.maxHeadY {
            column.headY -= cycleDistance
        }
        column.glyphs = (0..<column.length).map { _ in randomGlyph() }
        column.glowBoost = randomFloat(in: 0.85...1.25)
        column.brightness = randomFloat(in: 0.88...1.08)
        column.leadSpan = Int.random(in: 3...5)
        column.mutationInterval = Double.random(in: 0.15...0.34) * preferences.persistence
        column.mutationTimer = column.mutationInterval
        columns[index] = column
    }

    private func mutateColumn(at index: Int) {
        guard !columns[index].glyphs.isEmpty else { return }

        let activeRange = max(4, Int(CGFloat(columns[index].glyphs.count) * 0.34))
        let mutationCount = max(1, Int(CGFloat(activeRange) * 0.075))
        for _ in 0..<mutationCount {
            let glyphIndex = Int.random(in: 0..<activeRange)
            columns[index].glyphs[glyphIndex] = randomGlyph()
        }
    }

    private func makeBackgroundImage() -> CGImage? {
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        defer { image.unlockFocus() }

        guard let context = NSGraphicsContext.current?.cgContext else {
            return nil
        }

        let rect = bounds
        let darkness = CGFloat(preferences.darkness)
        let baseTintAlpha = 0.01 + (1.0 - darkness) * 0.02
        context.setFillColor(NSColor(calibratedRed: 0.0, green: 0.10, blue: 0.04, alpha: baseTintAlpha).cgColor)
        context.fill(rect)

        let intensity = CGFloat(preferences.moire) * 0.72
        if intensity > 0.001 {
            let blockWidth = max(6, floor(glyphFont.pointSize * 0.42))
            let blockHeight = max(4, floor(glyphFont.pointSize * 0.28))
            for y in stride(from: CGFloat(0), through: rect.height, by: blockHeight) {
                for x in stride(from: CGFloat(0), through: rect.width, by: blockWidth) {
                    let sample = sin((x * 0.031) + (y * 0.014)) + cos((x * 0.009) - (y * 0.027))
                    let alpha = (0.0015 + ((sample + 2.0) / 4.0) * 0.0065) * intensity
                    context.setFillColor(NSColor(calibratedRed: 0.0, green: 0.17, blue: 0.07, alpha: alpha).cgColor)
                    context.fill(CGRect(x: x, y: y, width: blockWidth, height: blockHeight))
                }
            }

            for y in stride(from: CGFloat(0), through: rect.height, by: 2) {
                let wave = sin(y * 0.017) + sin(y * 0.041) + cos(y * 0.007)
                let alpha = (0.004 + ((wave + 3.0) / 6.0) * 0.0105) * intensity
                context.setFillColor(NSColor(calibratedRed: 0.01, green: 0.24, blue: 0.10, alpha: alpha).cgColor)
                context.fill(CGRect(x: 0, y: y, width: rect.width, height: 1))
            }

            for y in stride(from: CGFloat(0), through: rect.height, by: 18) {
                let band = (sin(y * 0.011) + cos(y * 0.023) + 2.0) / 4.0
                let alpha = (0.003 + band * 0.012) * intensity
                context.setFillColor(NSColor(calibratedRed: 0.00, green: 0.18, blue: 0.07, alpha: alpha).cgColor)
                context.fill(CGRect(x: 0, y: y, width: rect.width, height: 2))
            }

            for x in stride(from: CGFloat(0), through: rect.width, by: 24) {
                let wave = cos(x * 0.05) + sin(x * 0.013)
                let alpha = (0.0022 + ((wave + 2.0) / 4.0) * 0.0058) * intensity
                context.setFillColor(NSColor(calibratedRed: 0.0, green: 0.14, blue: 0.05, alpha: alpha).cgColor)
                context.fill(CGRect(x: x, y: 0, width: 1, height: rect.height))
            }

            let bandCount = max(3, Int(rect.height / 210))
            for bandIndex in 0..<bandCount {
                let position = (CGFloat(bandIndex) + 0.5) / CGFloat(bandCount)
                let bandY = rect.height * position
                let bandHeight = max(16, rect.height * 0.04)
                let bandRect = CGRect(x: 0, y: bandY - bandHeight / 2, width: rect.width, height: bandHeight)
                let color = NSColor(calibratedRed: 0.0, green: 0.28, blue: 0.11, alpha: 0.016 * intensity)
                context.setFillColor(color.cgColor)
                context.fill(bandRect)
            }

            for y in stride(from: rect.height * 0.12, through: rect.height, by: rect.height * 0.19) {
                let tearHeight = max(3, floor(glyphFont.pointSize * 0.22))
                let alpha = 0.010 * intensity
                context.setFillColor(NSColor(calibratedRed: 0.05, green: 0.34, blue: 0.14, alpha: alpha).cgColor)
                context.fill(CGRect(x: 0, y: y, width: rect.width, height: tearHeight))
            }
        }

        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    private func updateRainLayers() {
        guard columnLayerSlots.count == columns.count else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for (columnIndex, column) in columns.enumerated() {
            let slots = columnLayerSlots[columnIndex]
            let columnBrightness = column.brightness
            let glow = CGFloat(preferences.glow) * column.glowBoost * columnBrightness
            let activeDepth = min(visibleGlyphDepth, min(column.length, slots.count))

            for offset in slots.indices {
                let slot = slots[offset]

                guard offset < activeDepth else {
                    hide(slot)
                    continue
                }

                let y = column.headY - (CGFloat(offset) * glyphStep)
                if y < -glyphStep || y > bounds.height + glyphStep {
                    hide(slot)
                    continue
                }

                let normalized = CGFloat(offset) / CGFloat(max(activeDepth - 1, 1))
                let baseAlpha = max(0.16, CGFloat(pow(Double(1.0 - normalized), 0.95)))
                let glyph = column.glyphs[offset]
                let point = NSPoint(x: column.x.rounded(.toNearestOrAwayFromZero), y: y.rounded(.toNearestOrAwayFromZero))

                if offset == 0 {
                    apply(
                        spriteKey: GlyphSpriteKey(glyph: glyph, style: .head),
                        alpha: 0.96,
                        at: point,
                        to: slot.mainLayer,
                        cachedKey: &slot.mainKey
                    )
                    apply(
                        spriteKey: GlyphSpriteKey(glyph: glyph, style: .headGlow),
                        alpha: 0.085 * glow,
                        at: NSPoint(x: point.x, y: point.y - 1),
                        to: slot.glowLayer,
                        cachedKey: &slot.glowKey
                    )
                } else if offset < column.leadSpan {
                    apply(
                        spriteKey: GlyphSpriteKey(glyph: glyph, style: .bright),
                        alpha: 0.88 * baseAlpha * columnBrightness,
                        at: point,
                        to: slot.mainLayer,
                        cachedKey: &slot.mainKey
                    )

                    if offset < 3 {
                        apply(
                            spriteKey: GlyphSpriteKey(glyph: glyph, style: .brightGlow),
                            alpha: 0.03 * glow * baseAlpha,
                            at: point,
                            to: slot.glowLayer,
                            cachedKey: &slot.glowKey
                        )
                    } else {
                        hideGlow(on: slot)
                    }
                } else {
                    apply(
                        spriteKey: GlyphSpriteKey(glyph: glyph, style: .trail),
                        alpha: 0.86 * baseAlpha * columnBrightness,
                        at: point,
                        to: slot.mainLayer,
                        cachedKey: &slot.mainKey
                    )
                    hideGlow(on: slot)
                }
            }
        }

        CATransaction.commit()
    }

    private func rebuildRainLayers() {
        guard !usesCatalinaRenderer else { return }
        configureLayerTree()

        let contentsScale = currentContentsScale()
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        rainLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        columnLayerSlots = columns.map { _ in
            (0..<visibleGlyphDepth).map { _ in
                let slot = GlyphSlotLayers(contentsScale: contentsScale)
                rainLayer.addSublayer(slot.glowLayer)
                rainLayer.addSublayer(slot.mainLayer)
                return slot
            }
        }

        CATransaction.commit()
    }

    private func configureLayerTree() {
        guard !usesCatalinaRenderer else { return }
        if layer == nil {
            layer = makeBackingLayer()
        }

        guard let rootLayer = layer else { return }
        let contentsScale = currentContentsScale()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        rootLayer.backgroundColor = NSColor.black.cgColor
        rootLayer.frame = bounds
        rootLayer.contentsScale = contentsScale

        if backgroundLayer.superlayer !== rootLayer {
            backgroundLayer.contentsGravity = .resize
            backgroundLayer.magnificationFilter = .nearest
            backgroundLayer.minificationFilter = .nearest
            backgroundLayer.actions = [
                "position": NSNull(),
                "bounds": NSNull(),
                "contents": NSNull(),
                "opacity": NSNull(),
                "frame": NSNull()
            ]
            rootLayer.addSublayer(backgroundLayer)
        }

        if rainLayer.superlayer !== rootLayer {
            rainLayer.isGeometryFlipped = true
            rainLayer.masksToBounds = true
            rainLayer.actions = [
                "position": NSNull(),
                "bounds": NSNull(),
                "opacity": NSNull(),
                "frame": NSNull(),
                "sublayers": NSNull()
            ]
            rootLayer.addSublayer(rainLayer)
        }

        backgroundLayer.frame = bounds
        backgroundLayer.contentsScale = contentsScale
        backgroundLayer.contents = backgroundImage

        rainLayer.frame = bounds
        for slots in columnLayerSlots {
            for slot in slots {
                slot.updateContentsScale(contentsScale)
            }
        }

        CATransaction.commit()
    }

    private func currentContentsScale() -> CGFloat {
        window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
    }

    private func drawCatalinaRain(in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.interpolationQuality = .none
        if let backgroundImage {
            context.draw(backgroundImage, in: bounds)
        }

        for column in columns {
            let columnBrightness = column.brightness
            let glow = CGFloat(preferences.glow) * column.glowBoost * columnBrightness
            let activeDepth = min(visibleGlyphDepth, column.length)

            for offset in 0..<activeDepth {
                let y = column.headY - (CGFloat(offset) * glyphStep)
                if y < -glyphStep || y > bounds.height + glyphStep {
                    continue
                }

                let normalized = CGFloat(offset) / CGFloat(max(activeDepth - 1, 1))
                let baseAlpha = max(0.16, CGFloat(pow(Double(1.0 - normalized), 0.95)))
                let glyph = column.glyphs[offset]
                let point = NSPoint(x: column.x.rounded(.toNearestOrAwayFromZero), y: y.rounded(.toNearestOrAwayFromZero))

                if offset == 0 {
                    draw(spriteKey: GlyphSpriteKey(glyph: glyph, style: .head), alpha: 0.96, at: point, in: context)
                    draw(spriteKey: GlyphSpriteKey(glyph: glyph, style: .headGlow), alpha: 0.085 * glow, at: NSPoint(x: point.x, y: point.y - 1), in: context)
                } else if offset < column.leadSpan {
                    draw(spriteKey: GlyphSpriteKey(glyph: glyph, style: .bright), alpha: 0.88 * baseAlpha * columnBrightness, at: point, in: context)
                    if offset < 3 {
                        draw(spriteKey: GlyphSpriteKey(glyph: glyph, style: .brightGlow), alpha: 0.03 * glow * baseAlpha, at: point, in: context)
                    }
                } else {
                    draw(spriteKey: GlyphSpriteKey(glyph: glyph, style: .trail), alpha: 0.86 * baseAlpha * columnBrightness, at: point, in: context)
                }
            }
        }
    }

    private func apply(
        spriteKey: GlyphSpriteKey,
        alpha: CGFloat,
        at point: NSPoint,
        to layer: CALayer,
        cachedKey: inout GlyphSpriteKey?
    ) {
        guard alpha > 0.001 else {
            layer.isHidden = true
            return
        }

        let sprite = glyphSprite(for: spriteKey.glyph, style: spriteKey.style)
        if cachedKey != spriteKey {
            layer.contents = sprite.cgImage
            cachedKey = spriteKey
        }

        let frame = CGRect(
            x: point.x + sprite.drawOffset.x,
            y: point.y + sprite.drawOffset.y,
            width: sprite.size.width,
            height: sprite.size.height
        )
        layer.frame = frame.integral
        layer.opacity = Float(alpha)
        layer.isHidden = false
    }

    private func draw(
        spriteKey: GlyphSpriteKey,
        alpha: CGFloat,
        at point: NSPoint,
        in context: CGContext
    ) {
        guard alpha > 0.001 else { return }

        let sprite = glyphSprite(for: spriteKey.glyph, style: spriteKey.style)
        let topAlignedRect = CGRect(
            x: point.x + sprite.drawOffset.x,
            y: point.y + sprite.drawOffset.y,
            width: sprite.size.width,
            height: sprite.size.height
        ).integral
        let drawRect = CGRect(
            x: topAlignedRect.origin.x,
            y: bounds.height - topAlignedRect.maxY,
            width: topAlignedRect.width,
            height: topAlignedRect.height
        )

        context.saveGState()
        context.setAlpha(alpha)
        context.draw(sprite.cgImage, in: drawRect)
        context.restoreGState()
    }

    private var shouldShowInlineControls: Bool {
        if isPreview {
            return true
        }

        let screenFrame = window?.screen?.frame ?? NSScreen.main?.frame ?? .zero
        guard !screenFrame.isEmpty else {
            return true
        }

        return bounds.width < screenFrame.width * 0.92 || bounds.height < screenFrame.height * 0.92
    }

    private func updatePreviewControlsButtonVisibility() {
        previewControlsButton.isHidden = !shouldShowInlineControls
    }

    private func hide(_ slot: GlyphSlotLayers) {
        slot.mainLayer.isHidden = true
        slot.glowLayer.isHidden = true
    }

    private func hideGlow(on slot: GlyphSlotLayers) {
        slot.glowLayer.isHidden = true
    }

    private func glyphSprite(for glyph: String, style: GlyphStyle) -> GlyphSprite {
        let key = GlyphSpriteKey(glyph: glyph, style: style)
        if let sprite = glyphSpriteCache[key] {
            return sprite
        }

        let sprite = makeGlyphSprite(for: glyph, style: style)
        glyphSpriteCache[key] = sprite
        return sprite
    }

    private func makeGlyphSprite(for glyph: String, style: GlyphStyle) -> GlyphSprite {
        let font = style.usesHeadFont ? headGlyphFont : glyphFont
        let padding = style.padding(for: font.pointSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: style.color()
        ]
        let attributedGlyph = NSAttributedString(string: glyph, attributes: attributes)
        let textSize = attributedGlyph.size()
        let size = NSSize(
            width: ceil(textSize.width + padding.width * 2),
            height: ceil(textSize.height + padding.height * 2)
        )

        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        attributedGlyph.draw(at: NSPoint(x: padding.width, y: padding.height))
        image.unlockFocus()
        image.isTemplate = false

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            let fallback = NSImage(size: size)
            fallback.lockFocus()
            attributedGlyph.draw(at: NSPoint(x: padding.width, y: padding.height))
            fallback.unlockFocus()
            let fallbackImage = fallback.cgImage(forProposedRect: nil, context: nil, hints: nil)!

            return GlyphSprite(
                cgImage: fallbackImage,
                drawOffset: NSPoint(x: -padding.width, y: -padding.height),
                size: size
            )
        }

        return GlyphSprite(
            cgImage: cgImage,
            drawOffset: NSPoint(x: -padding.width, y: -padding.height),
            size: size
        )
    }

    private func randomGlyph() -> String {
        glyphPool.randomElement() ?? "0"
    }

    private func randomFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat.random(in: range)
    }

    private var visibleGlyphDepth: Int {
        let baseDepth = isPreview ? 19.0 : 28.0
        let depth = Int(round(baseDepth * preferences.persistence))
        return max(16, min(64, depth))
    }

    private func sharedPreferencesURL() -> URL? {
        guard let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        return baseURL
            .appendingPathComponent(Self.preferencesDirectoryName, isDirectory: true)
            .appendingPathComponent(Self.preferencesFileName, isDirectory: false)
    }

    private func readSharedPreferences() -> Preferences? {
        guard
            let url = sharedPreferencesURL(),
            let data = try? Data(contentsOf: url),
            let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dictionary = object as? [String: Any]
        else {
            return nil
        }

        return Preferences(dictionary: dictionary).sanitized()
    }

    private func writeSharedPreferences(_ preferences: Preferences) {
        guard let url = sharedPreferencesURL() else { return }

        let directoryURL = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        if let data = try? PropertyListSerialization.data(fromPropertyList: preferences.dictionary(), format: .binary, options: 0) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func versionString() -> String {
        let shortVersion = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
        let buildVersion = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
        return "Version \(shortVersion) (\(buildVersion))"
    }

    private func makeConfigureSheet() -> NSWindow {
        sliderByKey.removeAll(keepingCapacity: true)
        valueLabelByKey.removeAll(keepingCapacity: true)

        let sheetRect = NSRect(x: 0, y: 0, width: 430, height: 410)
        let sheet = NSWindow(
            contentRect: sheetRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        sheet.title = "CodeRainSaver Options"
        sheet.isReleasedWhenClosed = false
        sheet.animationBehavior = .documentWindow
        sheet.standardWindowButton(.miniaturizeButton)?.isHidden = true
        sheet.standardWindowButton(.zoomButton)?.isHidden = true
        sheet.contentMinSize = sheetRect.size
        sheet.contentMaxSize = sheetRect.size

        let viewController = NSViewController()
        let contentView = NSView(frame: NSRect(origin: .zero, size: sheetRect.size))
        viewController.view = contentView
        sheet.contentViewController = viewController

        let titleLabel = NSTextField(labelWithString: "Tune the rain")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let subtitleLabel = NSTextField(labelWithString: "Changes save immediately and apply to the preview live.")
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.font = .systemFont(ofSize: 12)

        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 12

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        for key in PreferenceKey.allCases {
            let row = makeSliderRow(for: key)
            stackView.addArrangedSubview(row)
        }

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        let restoreButton = NSButton(title: "Restore Defaults", target: self, action: #selector(restoreDefaults))
        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeConfigureSheet))
        doneButton.keyEquivalent = "\r"
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let versionLabel = NSTextField(labelWithString: versionString())
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.font = .systemFont(ofSize: 11)

        buttonRow.addArrangedSubview(restoreButton)
        buttonRow.addArrangedSubview(doneButton)
        buttonRow.addArrangedSubview(spacer)
        buttonRow.addArrangedSubview(versionLabel)
        stackView.addArrangedSubview(buttonRow)

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        return sheet
    }

    private func makeSliderRow(for key: PreferenceKey) -> NSView {
        let container = NSStackView()
        container.orientation = .horizontal
        container.alignment = .centerY
        container.spacing = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: key.title)
        label.frame.size.width = 92
        label.alignment = .right

        let slider = NSSlider(value: preferences.value(for: key), minValue: key.range.lowerBound, maxValue: key.range.upperBound, target: self, action: #selector(settingSliderChanged(_:)))
        slider.identifier = NSUserInterfaceItemIdentifier(key.rawValue)
        slider.controlSize = .regular

        let valueLabel = NSTextField(labelWithString: formattedValue(preferences.value(for: key)))
        valueLabel.alignment = .right
        valueLabel.frame.size.width = 46
        valueLabel.textColor = .secondaryLabelColor

        sliderByKey[key] = slider
        valueLabelByKey[key] = valueLabel

        container.addArrangedSubview(label)
        container.addArrangedSubview(slider)
        container.addArrangedSubview(valueLabel)

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 92),
            valueLabel.widthAnchor.constraint(equalToConstant: 46),
            slider.widthAnchor.constraint(equalToConstant: 220)
        ])

        return container
    }

    private func refreshConfigureSheetControls() {
        for key in PreferenceKey.allCases {
            let value = preferences.value(for: key)
            sliderByKey[key]?.doubleValue = value
            valueLabelByKey[key]?.stringValue = formattedValue(value)
        }
    }

    private func formattedValue(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    @objc private func settingSliderChanged(_ sender: NSSlider) {
        guard
            let identifier = sender.identifier?.rawValue,
            let key = PreferenceKey(rawValue: identifier)
        else {
            return
        }

        preferences.setValue(sender.doubleValue, for: key)
        valueLabelByKey[key]?.stringValue = formattedValue(sender.doubleValue)
        savePreferences()
        rebuildColumns()
    }

    @objc private func restoreDefaults() {
        preferences = .standard
        savePreferences()
        refreshConfigureSheetControls()
        rebuildColumns()
    }

    @objc private func openPreviewControls() {
        guard shouldShowInlineControls, let sheet = configureSheet else { return }

        refreshConfigureSheetControls()

        if sheet.sheetParent != nil {
            return
        }

        if sheet.isVisible {
            sheet.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        sheet.level = .floating
        sheet.collectionBehavior = [.moveToActiveSpace]

        if let previewWindow = window {
            let origin = NSPoint(
                x: previewWindow.frame.midX - (sheet.frame.width / 2),
                y: previewWindow.frame.midY - (sheet.frame.height / 2)
            )
            sheet.setFrameOrigin(origin)
        } else {
            sheet.center()
        }

        NSApp.activate(ignoringOtherApps: true)
        sheet.makeKeyAndOrderFront(nil)
    }

    @objc private func handleExternalPreferencesChange(_ notification: Notification) {
        _ = applyExternalPreferencesIfNeeded()
    }

    @objc private func closeConfigureSheet() {
        guard let sheet = configureSheetWindow else { return }

        sheet.level = .normal

        if let parent = sheet.sheetParent {
            parent.endSheet(sheet)
            sheet.orderOut(nil)
        } else {
            sheet.close()
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
