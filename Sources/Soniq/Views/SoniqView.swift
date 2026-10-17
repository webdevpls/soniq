import CoreAudio
import SwiftUI

private enum Tab: String, CaseIterable {
    case apps, effects, test

    var title: String {
        switch self {
        case .apps: return "Apps"
        case .effects: return "Effects"
        case .test: return "Test"
        }
    }

    var symbol: String {
        switch self {
        case .apps: return "square.grid.2x2.fill"
        case .effects: return "sparkles"
        case .test: return "headphones"
        }
    }
}

struct SoniqView: View {
    @EnvironmentObject private var model: SoniqModel
    @State private var tab: Tab = .apps
    @State private var picker: Picker?
    @State private var showSettings = false
    @Namespace private var tabNamespace
    @AppStorage(PanelSettings.showMic) private var showMic = true
    @AppStorage(PanelSettings.showEffects) private var showEffects = true
    @AppStorage(PanelSettings.showTest) private var showTest = true
    @AppStorage(AppLanguage.key) private var language = "system"

    private var tabs: [Tab] {
        Tab.allCases.filter { ($0 != .effects || showEffects) && ($0 != .test || showTest) }
    }

    private enum Picker { case output, input }

    var body: some View {
        VStack(spacing: 8) {
            if showSettings {
                SettingsView { showSettings = false }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                Group {
                    devicesCard
                    if model.permission == .denied { PermissionBanner() }
                    if tabs.count > 1 { tabBar }
                    Group {
                        switch tabs.contains(tab) ? tab : .apps {
                        case .apps: AppsTab()
                        case .effects: EffectsTab()
                        case .test: TestTab()
                        }
                    }
                    .transition(.opacity)
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            footer
        }
        .padding(10)
        .frame(width: 292)
        .background(AmbientBackground())
        .animation(.snappy(duration: 0.28), value: tab)
        .animation(.snappy(duration: 0.3), value: showSettings)
        .id(language)
    }

    // MARK: Output & mic

    private var devicesCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                MixerSlider(
                    value: Binding(get: { model.outputMuted ? 0 : model.outputLevel }, set: model.setOutputLevel),
                    maxValue: 2,
                    title: model.boost > 1.001 ? "Boost" : (model.output?.name ?? "Output"),
                    detail: model.outputMuted ? "Muted" : "\(Int((model.outputLevel * 100).rounded()))%",
                    height: 34,
                    gradient: Theme.boost,
                    enabled: model.outputAdjustable || model.boost > 1,
                    onLeadingTap: model.toggleOutputMute
                ) {
                    Image(systemName: model.outputMuted ? "speaker.slash.fill" : (model.boost > 1.001 ? "flame.fill" : "speaker.wave.3.fill"),
                          variableValue: Double(min(model.outputLevel, 1)))
                        .font(.system(size: 12, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                }
                pickerButton(.output)
            }

            if picker == .output {
                DeviceList(devices: model.outputs, selected: model.outputID, symbol: { $0.symbol }, select: model.selectOutput)
            }

            if showMic {
            HStack(spacing: 6) {
                MixerSlider(
                    value: Binding(get: { model.inputMuted ? 0 : model.inputVolume }, set: model.setInputVolume),
                    title: model.input?.name ?? "Microphone",
                    detail: model.inputMuted ? "Muted" : "\(Int((model.inputVolume * 100).rounded()))%",
                    height: 28,
                    gradient: Theme.mic,
                    enabled: model.inputAdjustable,
                    onLeadingTap: model.toggleInputMute
                ) {
                    Image(systemName: model.inputMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                }
                RoundButton(symbol: model.inputMuted ? "mic.slash.fill" : "mic.fill", size: 26,
                            active: model.inputMuted, help: model.inputMuted ? "Unmute microphone" : "Mute microphone") {
                    model.toggleInputMute()
                }
                pickerButton(.input)
            }

            if picker == .input {
                VStack(spacing: 2) {
                    DeviceList(devices: model.inputs, selected: model.inputID, symbol: { $0.inputSymbol }, select: model.selectInput)
                    HStack {
                        Text(L("Keep this microphone"))
                            .font(.system(size: 11.5))
                        Spacer()
                        Toggle("", isOn: Binding(get: { model.lockInput }, set: model.setLockInput))
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .help(L("Don't switch to a headset mic when it connects"))
                    HStack {
                        Text(L("Lock microphone level"))
                            .font(.system(size: 11.5))
                        Spacer()
                        Toggle("", isOn: Binding(get: { model.lockInputLevel }, set: model.setLockInputLevel))
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .help(L("Stop call apps from raising your mic level"))
                }
            }
            }
        }
        .padding(10)
        .glassCard()
        .animation(.snappy(duration: 0.3), value: picker)
    }

    private func pickerButton(_ kind: Picker) -> some View {
        RoundButton(symbol: "chevron.down", size: 26, active: picker == kind, help: kind == .output ? "Output device" : "Microphone") {
            picker = picker == kind ? nil : kind
        }
        .rotationEffect(.degrees(picker == kind ? 180 : 0))
    }

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(tabs, id: \.self) { item in
                let selected = item == tab
                Button {
                    tab = item
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: item.symbol).font(.system(size: 10, weight: .semibold))
                        Text(L(item.title)).font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if selected {
                            Capsule(style: .continuous)
                                .fill(Color.primary.opacity(0.13))
                                .matchedGeometryEffect(id: "tab", in: tabNamespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .glassCapsule()
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 6) {
            BrandLogo()
            Spacer()
            RoundButton(symbol: "gearshape.fill", size: 24, active: showSettings, help: "Settings") {
                showSettings.toggle()
            }

            RoundButton(symbol: "power", size: 24, help: "Quit Soniq") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(.horizontal, 4)
    }
}

private struct PermissionBanner: View {
    @EnvironmentObject private var model: SoniqModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 14))
                .foregroundStyle(LinearGradient(gradient: Theme.warm, startPoint: .top, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 1) {
                Text(L("Audio access needed")).font(.system(size: 11.5, weight: .semibold))
                Text(L("Allow Soniq in System Audio Recording.")).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button(L("Allow")) { model.requestPermission() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(LinearGradient(gradient: Theme.warm, startPoint: .leading, endPoint: .trailing)))
        }
        .padding(10)
        .glassCard(cornerRadius: 14)
    }
}

// MARK: - Apps

private struct AppsTab: View {
    @EnvironmentObject private var model: SoniqModel
    @State private var expanded: String?
    @AppStorage(PanelSettings.onlyPlaying) private var onlyPlaying = false

    var body: some View {
        let apps = onlyPlaying ? model.apps.filter(\.isPlaying) : model.apps
        let rows = CGFloat(apps.count) * 36 + (expanded != nil ? 28 : 0)

        Group {
            if apps.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text(L("Nothing is playing"))
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(apps) { app in
                            AppRow(app: app, expanded: Binding(
                                get: { expanded == app.id },
                                set: { expanded = $0 ? app.id : nil }
                            ))
                        }
                    }
                    .padding(10)
                }
                .frame(height: min(rows + 14, 300))
            }
        }
        .glassCard()
        .animation(.snappy(duration: 0.3), value: model.apps)
        .animation(.snappy(duration: 0.25), value: expanded)
    }
}

private struct AppRow: View {
    @EnvironmentObject private var model: SoniqModel
    let app: MixerApp
    @Binding var expanded: Bool

    var body: some View {
        let muted = model.isMuted(app.id)
        let volume = model.volume(for: app.id)
        let balance = model.balance(for: app.id)

        VStack(spacing: 6) {
            HStack(spacing: 6) {
                MixerSlider(
                    value: Binding(get: { muted ? 0 : volume }, set: { model.setVolume($0, for: app.id) }),
                    title: app.name,
                    detail: muted ? "Muted" : "\(Int((volume * 100).rounded()))%",
                    height: 30,
                    gradient: Theme.soft,
                    dimmed: muted,
                    onLeadingTap: { model.toggleMute(app.id) }
                ) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 22, height: 22)
                        .saturation(muted ? 0 : 1)
                        .opacity(muted ? 0.5 : 1)
                        .overlay(alignment: .topTrailing) {
                            if app.isPlaying && !muted {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.5))
                                    .offset(x: 2, y: -1)
                            }
                        }
                }
                RoundButton(symbol: "arrow.left.and.right", size: 22, active: balance != 0 || expanded, help: "Left / right balance") {
                    expanded.toggle()
                }
            }
            if expanded {
                CenterSlider(value: Binding(get: { balance }, set: { model.setBalance($0, for: app.id) }),
                             leftLabel: "L", rightLabel: "R")
                    .padding(.trailing, 28)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }
}

// MARK: - Effects

private struct EffectsTab: View {
    @EnvironmentObject private var model: SoniqModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(SoundEffect.all) { effect in
                    EffectTile(effect: effect, colors: Theme.effectColors(effect.id),
                               selected: model.effectID == effect.id) {
                        model.selectEffect(effect.id)
                    }
                }
            }

            VStack(spacing: 7) {
                MixerSlider(
                    value: Binding(get: { model.intensity }, set: model.setIntensity),
                    title: "Intensity",
                    detail: "\(Int((model.intensity * 100).rounded()))%",
                    height: 24,
                    enabled: model.effectID != SoundEffect.off.id
                ) {
                    Image(systemName: "sparkles").font(.system(size: 9, weight: .bold))
                }
                ToneRow(title: "Bass", value: model.bass, set: model.setBass)
                ToneRow(title: "Treble", value: model.treble, set: model.setTreble)
            }
        }
        .padding(10)
        .glassCard()
    }
}

private struct ToneRow: View {
    let title: String
    let value: Float
    let set: (Float) -> Void
    private let range: Float = 8

    var body: some View {
        HStack(spacing: 8) {
            Text(L(title))
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            CenterSlider(value: Binding(get: { value / range }, set: { set($0 * range) }), leftLabel: "−", rightLabel: "+")
            Text(value == 0 ? "0 dB" : String(format: "%+.0f dB", value))
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 34, alignment: .trailing)
        }
    }
}

private struct EffectTile: View {
    let effect: SoundEffect
    let colors: [Color]
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: effect.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selected ? Color.white : Color.primary.opacity(0.75))
                    .shadow(color: selected ? .black.opacity(0.2) : .clear, radius: 1, y: 0.5)
                    .symbolEffect(.bounce, value: selected)
                Text(L(effect.name))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(selected ? Color.white.opacity(0.95) : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
                if selected {
                    // Liquid tile: soft two-tone gradient, a highlight bloom and a glass rim.
                    shape
                        .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(
                            shape.fill(RadialGradient(colors: [.white.opacity(0.35), .clear],
                                                      center: .topLeading, startRadius: 0, endRadius: 60))
                        )
                        .overlay(
                            shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                                              startPoint: .top, endPoint: .bottom), lineWidth: 0.75)
                        )
                        .shadow(color: colors[0].opacity(0.4), radius: 6, y: 2)
                        .transition(.opacity)
                } else {
                    shape.fill(Color.primary.opacity(hovering ? 0.1 : 0.05))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.2), value: selected)
    }
}

// MARK: - Devices

private struct DeviceList: View {
    let devices: [AudioDevice]
    let selected: AudioObjectID
    let symbol: (AudioDevice) -> String
    let select: (AudioDevice) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(devices) { device in
                DeviceRow(name: device.name, symbol: symbol(device), selected: device.id == selected) { select(device) }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct DeviceRow: View {
    let name: String
    let symbol: String
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(selected ? Color.black.opacity(0.75) : Color.primary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(selected ? Color.white : Color.primary.opacity(0.1)))
                Text(name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(hovering ? 0.08 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
