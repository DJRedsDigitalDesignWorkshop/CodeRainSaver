import AppKit
import ScreenSaver

private let preferencesChangedNotification = Notification.Name("com.justinmarsh.coderainsaver.preferencesChanged")
private let preferencesDirectoryName = "CodeRainSaver"
private let preferencesFileName = "preferences.plist"

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

private struct Preferences {
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

private final class SettingsViewController: NSViewController {
    private let moduleName = "com.justinmarsh.coderainsaver"
    private var preferences = Preferences.standard
    private var sliderByKey: [PreferenceKey: NSSlider] = [:]
    private var valueLabelByKey: [PreferenceKey: NSTextField] = [:]

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 430))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadPreferences()
        buildUI()
    }

    private func loadPreferences() {
        if let sharedPreferences = readSharedPreferences() {
            preferences = sharedPreferences
            return
        }

        guard let defaults = ScreenSaverDefaults(forModuleWithName: moduleName) else {
            preferences = .standard
            return
        }

        defaults.synchronize()
        defaults.register(defaults: Preferences.standard.dictionary())
        preferences = Preferences(
            speedMultiplier: defaults.double(forKey: PreferenceKey.speedMultiplier.rawValue),
            darkness: defaults.double(forKey: PreferenceKey.darkness.rawValue),
            moire: defaults.double(forKey: PreferenceKey.moire.rawValue),
            persistence: defaults.double(forKey: PreferenceKey.persistence.rawValue),
            density: defaults.double(forKey: PreferenceKey.density.rawValue),
            glow: defaults.double(forKey: PreferenceKey.glow.rawValue),
            glyphScale: defaults.double(forKey: PreferenceKey.glyphScale.rawValue)
        ).sanitized()
        writeSharedPreferences(preferences)
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
        DistributedNotificationCenter.default().post(name: preferencesChangedNotification, object: nil)
    }

    private func sharedPreferencesURL() -> URL? {
        guard let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        return baseURL
            .appendingPathComponent(preferencesDirectoryName, isDirectory: true)
            .appendingPathComponent(preferencesFileName, isDirectory: false)
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

    private func buildUI() {
        let root = NSStackView()
        root.translatesAutoresizingMaskIntoConstraints = false
        root.orientation = .vertical
        root.spacing = 12
        root.alignment = .leading

        let titleLabel = NSTextField(labelWithString: "CodeRainSaver Controls")
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        let subtitleLabel = NSTextField(labelWithString: "Tahoe's Options button is unreliable for third-party savers, so this app edits the same settings directly.")
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.lineBreakMode = .byWordWrapping

        root.addArrangedSubview(titleLabel)
        root.addArrangedSubview(subtitleLabel)

        for key in PreferenceKey.allCases {
            root.addArrangedSubview(makeSliderRow(for: key))
        }

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        let restoreButton = NSButton(title: "Restore Defaults", target: self, action: #selector(restoreDefaults))
        let quitButton = NSButton(title: "Done", target: self, action: #selector(closeApp))
        quitButton.keyEquivalent = "\r"

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let hintLabel = NSTextField(labelWithString: "Changes apply to the saver immediately.")
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor

        buttonRow.addArrangedSubview(restoreButton)
        buttonRow.addArrangedSubview(quitButton)
        buttonRow.addArrangedSubview(spacer)
        buttonRow.addArrangedSubview(hintLabel)
        root.addArrangedSubview(buttonRow)

        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            root.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])
    }

    private func makeSliderRow(for key: PreferenceKey) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let label = NSTextField(labelWithString: key.title)
        label.alignment = .right

        let slider = NSSlider(
            value: preferences.value(for: key),
            minValue: key.range.lowerBound,
            maxValue: key.range.upperBound,
            target: self,
            action: #selector(settingSliderChanged(_:))
        )
        slider.identifier = NSUserInterfaceItemIdentifier(key.rawValue)

        let valueLabel = NSTextField(labelWithString: formattedValue(preferences.value(for: key)))
        valueLabel.alignment = .right
        valueLabel.textColor = .secondaryLabelColor

        sliderByKey[key] = slider
        valueLabelByKey[key] = valueLabel

        row.addArrangedSubview(label)
        row.addArrangedSubview(slider)
        row.addArrangedSubview(valueLabel)

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 92),
            valueLabel.widthAnchor.constraint(equalToConstant: 46),
            slider.widthAnchor.constraint(equalToConstant: 235)
        ])

        return row
    }

    private func formattedValue(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    @objc private func settingSliderChanged(_ sender: NSSlider) {
        guard
            let rawValue = sender.identifier?.rawValue,
            let key = PreferenceKey(rawValue: rawValue)
        else {
            return
        }

        preferences.setValue(sender.doubleValue, for: key)
        valueLabelByKey[key]?.stringValue = formattedValue(sender.doubleValue)
        savePreferences()
    }

    @objc private func restoreDefaults() {
        preferences = .standard
        savePreferences()

        for key in PreferenceKey.allCases {
            let value = preferences.value(for: key)
            sliderByKey[key]?.doubleValue = value
            valueLabelByKey[key]?.stringValue = formattedValue(value)
        }
    }

    @objc private func closeApp() {
        NSApp.terminate(nil)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let viewController = SettingsViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CodeRainSaver Controls"
        window.contentViewController = viewController
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
