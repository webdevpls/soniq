import SwiftUI

enum PanelSettings {
    static let showMic = "showMic"
    static let showEffects = "showEffects"
    static let showTest = "showTest"
    static let onlyPlaying = "onlyPlaying"
}

struct SettingsView: View {
    var onBack: () -> Void
    @EnvironmentObject private var model: SoniqModel
    @AppStorage(PanelSettings.showMic) private var showMic = true
    @AppStorage(PanelSettings.showEffects) private var showEffects = true
    @AppStorage(PanelSettings.showTest) private var showTest = true
    @AppStorage(PanelSettings.onlyPlaying) private var onlyPlaying = false

    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                RoundButton(symbol: "chevron.left", size: 26, help: "Back", action: onBack)
                    .keyboardShortcut(.cancelAction)
                Text(L("Settings"))
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 2)
            .padding(.top, 2)

            section("Show in Menu") {
                SettingRow(symbol: "mic.fill", title: "Microphone", isOn: $showMic)
                SettingRow(symbol: "sparkles", title: "Effects", isOn: $showEffects)
                SettingRow(symbol: "headphones", title: "Headphone Test", isOn: $showTest)
                SettingRow(symbol: "waveform", title: "Only Playing Apps", isOn: $onlyPlaying)
            }

            section("General") {
                LanguageRow()
                SettingRow(symbol: "power.circle.fill", title: "Launch at Login", isOn: $model.launchAtLogin)
                SettingRow(symbol: "lock.fill", title: "Keep Chosen Microphone",
                           isOn: Binding(get: { model.lockInput }, set: model.setLockInput))
                LinkRow(symbol: "speaker.wave.2.fill", title: "Sound Settings…") {
                    open("x-apple.systempreferences:com.apple.Sound-Settings.extension")
                }
                LinkRow(symbol: "lock.shield.fill", title: "Audio Permission…") {
                    AudioCapturePermission.openSettings()
                }
            }

            Text(String(format: L("Soniq %@ · Developed by Vision Tech"), Self.version))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.quaternary)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L(title).uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
            VStack(spacing: 2) { content() }
                .padding(6)
                .glassCard(cornerRadius: 16)
        }
    }

    private func open(_ string: String) {
        if let url = URL(string: string) { NSWorkspace.shared.open(url) }
    }
}

private struct SettingRow: View {
    let symbol: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 9) {
            RoundIcon(symbol: symbol, size: 24, active: isOn)
            Text(L(title)).font(.system(size: 12))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
        .animation(.snappy(duration: 0.2), value: isOn)
    }
}

private struct LinkRow: View {
    let symbol: String
    let title: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                RoundIcon(symbol: symbol, size: 24)
                Text(L(title)).font(.system(size: 12))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(hovering ? 0.07 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct LanguageRow: View {
    @AppStorage(AppLanguage.key) private var language = "system"

    var body: some View {
        HStack(spacing: 9) {
            RoundIcon(symbol: "globe", size: 24)
            Text(L("Language")).font(.system(size: 12))
            Spacer()
            Menu {
                ForEach(AppLanguage.options, id: \.code) { option in
                    Button {
                        language = option.code
                    } label: {
                        if option.code == language {
                            Label(L(option.name), systemImage: "checkmark")
                        } else {
                            Text(L(option.name))
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(L(AppLanguage.options.first { $0.code == language }?.name ?? "Automatic"))
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 8, weight: .bold))
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}
