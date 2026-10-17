import SwiftUI

struct TestTab: View {
    @EnvironmentObject private var model: SoniqModel
    @EnvironmentObject private var tester: HeadphoneTester

    var body: some View {
        let earbuds = model.output?.isAirPods ?? false

        VStack(spacing: 8) {
            HStack(spacing: 6) {
                SideTile(title: "Left", symbol: earbuds ? "airpod.left" : "l.circle.fill", test: .left, colors: [Theme.violet, Theme.blue])
                SideTile(title: "Both", symbol: model.output?.symbol ?? "headphones", test: .both, colors: [Theme.blue, Theme.teal])
                SideTile(title: "Right", symbol: earbuds ? "airpod.right" : "r.circle.fill", test: .right, colors: [Theme.teal, Theme.mint])
            }

            VStack(spacing: 2) {
                TestRow(test: .sweep, title: "Stereo Sweep", subtitle: "Sound moves left ↔ right", symbol: "arrow.left.and.right") {
                    PanIndicator(pan: tester.pan)
                }
                TestRow(test: .frequency, title: "Frequency Range", subtitle: "20 Hz → 20 kHz", symbol: "waveform.path") {
                    Text(Self.format(tester.frequency))
                }
                TestRow(test: .bass, title: "Bass Response", subtitle: "Deep tones, 25–160 Hz", symbol: "speaker.wave.3.fill") {
                    Text(Self.format(tester.frequency))
                }
                TestRow(test: .phase, title: "Phase Check", subtitle: "Second half should sound hollow", symbol: "circle.lefthalf.filled") {
                    Text(L(tester.inverted ? "Inverted" : "In phase"))
                }
            }
        }
        .padding(10)
        .glassCard()
        .onDisappear { tester.stop() }
    }

    static func format(_ hz: Double) -> String {
        hz >= 1000 ? String(format: "%.1f kHz", hz / 1000) : String(format: "%.0f Hz", hz)
    }
}

private struct SideTile: View {
    @EnvironmentObject private var tester: HeadphoneTester
    let title: String
    let symbol: String
    let test: HeadphoneTester.Test
    let colors: [Color]
    @State private var hovering = false

    var body: some View {
        let active = tester.running == test

        Button { tester.toggle(test) } label: {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(active ? Color.black.opacity(0.8) : Color.primary.opacity(0.75))
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: active)
                    .symbolEffect(.pulse, options: .repeating, isActive: active)
                Text(L(title))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(active ? Color.black.opacity(0.7) : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(active ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.primary.opacity(hovering ? 0.1 : 0.05)))
                    .shadow(color: active ? .black.opacity(0.15) : .clear, radius: 2, y: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.2), value: active)
    }
}

private struct TestRow<Readout: View>: View {
    @EnvironmentObject private var tester: HeadphoneTester
    let test: HeadphoneTester.Test
    let title: String
    let subtitle: String
    let symbol: String
    @ViewBuilder var readout: Readout
    @State private var hovering = false

    var body: some View {
        let active = tester.running == test

        Button { tester.toggle(test) } label: {
            VStack(spacing: 6) {
                HStack(spacing: 9) {
                    RoundIcon(symbol: active ? "stop.fill" : symbol, size: 26, active: active)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(L(title)).font(.system(size: 11.5, weight: .semibold))
                        Text(L(subtitle)).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    if active {
                        readout
                            .font(.system(size: 10.5, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                }
                if active {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.08))
                            Capsule()
                                .fill(Color.primary.opacity(0.55))
                                .frame(width: geo.size.width * tester.progress)
                        }
                    }
                    .frame(height: 3)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(hovering || active ? 0.07 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.25), value: active)
    }
}

private struct PanIndicator: View {
    let pan: Double

    var body: some View {
        ZStack {
            Capsule().fill(Color.primary.opacity(0.1)).frame(width: 44, height: 4)
            Circle()
                .fill(Color.primary.opacity(0.8))
                .frame(width: 9, height: 9)
                .offset(x: pan * 18)
        }
        .frame(width: 46)
    }
}
