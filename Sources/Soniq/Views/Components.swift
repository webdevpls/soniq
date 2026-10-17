import SwiftUI

enum Theme {
    static let violet = Color(red: 0.56, green: 0.46, blue: 1.0)
    static let blue = Color(red: 0.27, green: 0.6, blue: 1.0)
    static let teal = Color(red: 0.3, green: 0.84, blue: 0.86)
    static let mint = Color(red: 0.36, green: 0.86, blue: 0.62)
    static let pink = Color(red: 1.0, green: 0.43, blue: 0.69)
    static let orange = Color(red: 1.0, green: 0.62, blue: 0.32)

    /// Fills are near-white with only a hint of tint, like Control Center.
    static let main = Gradient(colors: [Color(white: 1), Color(white: 0.9)])
    static let mic = Gradient(colors: [Color(white: 1), Color(red: 0.86, green: 0.95, blue: 0.93)])
    static let soft = Gradient(colors: [Color(white: 0.96), Color(white: 0.86)])
    static let warm = Gradient(colors: [pink, orange])
    /// 0–100% neutral, 100–200% warms up gently.
    static let boost = Gradient(stops: [
        .init(color: Color(white: 1), location: 0), .init(color: Color(white: 0.92), location: 0.5),
        .init(color: Color(red: 1, green: 0.86, blue: 0.78), location: 0.7),
        .init(color: Color(red: 1, green: 0.74, blue: 0.62), location: 1),
    ])
    static let accent = Color.primary

    /// Slider tracks get their own nearly opaque color: Liquid Glass brightens over light
    /// windows, and a translucent track would then look the same as the white fill.
    static func track(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.17).opacity(0.9) : Color(white: 0.7).opacity(0.6)
    }

    /// Each effect has its own soft gradient when selected.
    static func effectColors(_ id: String) -> [Color] {
        func rgb(_ hex: UInt32) -> Color {
            Color(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
        }
        let pairs: [String: (UInt32, UInt32)] = [
            "off": (0x9AA0AE, 0x5C6270),
            "bass": (0xFF7A93, 0xFF9E6B),
            "party": (0xF56BD8, 0x9B6BFF),
            "underwater": (0x4FD4FF, 0x3A7BFF),
            "concert": (0xF7C25A, 0xE8833F),
            "nextRoom": (0x9DA8C4, 0x66718F),
            "car": (0xFF8A4C, 0xFF4F6B),
            "radio": (0x7EDC94, 0x33B38C),
            "wide": (0x6F8CFF, 0x4CD8F0),
            "vocal": (0xFF9CC2, 0xFF6688),
            "night": (0x6A5AE0, 0x2F2C86),
            "cinema": (0xB45CFF, 0x5E46F0),
        ]
        let pair = pairs[id] ?? (0x6F8CFF, 0x4CD8F0)
        return [rgb(pair.0), rgb(pair.1)]
    }
}

/// Soft colored light behind the glass panels.
struct AmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let strength = colorScheme == .dark ? 0.12 : 0.07
        ZStack {
            // A light base tint keeps the glass legible over bright windows.
            Rectangle().fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.35))

            ZStack {
                Circle().fill(Theme.violet).frame(width: 220).offset(x: -110, y: -170)
                Circle().fill(Theme.teal).frame(width: 200).offset(x: 120, y: 30)
                Circle().fill(Theme.pink).frame(width: 180).offset(x: -60, y: 220)
            }
            .opacity(strength)
            .blur(radius: 70)
        }
        .allowsHitTesting(false)
    }
}

/// Thick capsule slider with the icon, title and value inside. Text turns white over the fill.
struct MixerSlider<Leading: View>: View {
    @Binding var value: Float
    var maxValue: Float = 1
    var title: String
    var detail: String
    var height: CGFloat = 32
    var gradient: Gradient = Theme.main
    var dimmed = false
    var enabled = true
    var onLeadingTap: (() -> Void)?
    @ViewBuilder var leading: Leading

    @State private var dragging = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fraction = CGFloat(min(max(value / maxValue, 0), 1))
            let fill = height + fraction * (width - height)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Theme.track(colorScheme))
                    .glassTrack()

                if maxValue > 1 {
                    // 100% marker for boost.
                    Capsule()
                        .fill(Color.primary.opacity(0.3))
                        .frame(width: 2, height: height * 0.4)
                        .offset(x: height + (width - height) / CGFloat(maxValue) - 1)
                }

                // Glass fill: gradient mapped to the full track so boost colors stay in place.
                Capsule(style: .continuous)
                    .fill(LinearGradient(gradient: gradient, startPoint: .leading,
                                         endPoint: UnitPoint(x: width / max(fill, 1), y: 0.5)))
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)],
                                                 startPoint: .top, endPoint: .center))
                            .padding(1)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.2)],
                                                         startPoint: .top, endPoint: .bottom), lineWidth: 0.75)
                    )
                    .frame(width: fill)
                    .opacity(dimmed ? 0.4 : 1)
                    .shadow(color: .black.opacity(dimmed ? 0 : 0.25), radius: 3, y: 1)

                labels.foregroundStyle(Color.primary)
                labels
                    .foregroundStyle(Color.black.opacity(0.78))
                    .mask(alignment: .leading) { Rectangle().frame(width: fill) }

                leading
                    .foregroundStyle(Color.black.opacity(0.6))
                    .frame(width: height, height: height)
            }
            .contentShape(Capsule())
            .gesture(drag(width: width))
        }
        .frame(height: height)
        .scaleEffect(dragging ? 1.015 : 1)
        .opacity(enabled ? 1 : 0.45)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.9), value: value)
    }

    private var labels: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(detail)
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .opacity(0.75)
                .contentTransition(.numericText())
        }
        .padding(.leading, height)
        .padding(.trailing, 12)
    }

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard enabled else { return }
                // A touch that starts on the icon is a tap until it moves.
                let onIcon = onLeadingTap != nil && gesture.startLocation.x < height
                if onIcon && abs(gesture.translation.width) < 4 { return }
                if !dragging { withAnimation(.snappy(duration: 0.18)) { dragging = true } }
                let usable = max(width - height, 1)
                var v = Float(min(max((gesture.location.x - height / 2) / usable, 0), 1)) * maxValue
                if maxValue > 1 && abs(v - 1) < 0.03 { v = 1 } // detent at 100%
                value = v
            }
            .onEnded { gesture in
                if let onLeadingTap, gesture.startLocation.x < height, abs(gesture.translation.width) < 4 {
                    onLeadingTap()
                }
                withAnimation(.snappy(duration: 0.25)) { dragging = false }
            }
    }
}

/// Bipolar slider (-1 … 1) with a center detent: balance, bass, treble.
struct CenterSlider: View {
    @Binding var value: Float
    var leftLabel: String
    var rightLabel: String
    var gradient: Gradient = Theme.main
    var height: CGFloat = 20

    @State private var dragging = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let knob = height - 4
            let usable = width - knob - 4
            let x = 2 + knob / 2 + CGFloat((value + 1) / 2) * usable
            let mid = width / 2

            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track(colorScheme))
                HStack {
                    Text(leftLabel)
                    Spacer()
                    Text(rightLabel)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)

                Capsule().fill(Color.primary.opacity(0.2)).frame(width: 1.5, height: height * 0.45).offset(x: mid - 0.75)

                Capsule()
                    .fill(Color.primary.opacity(0.45))
                    .frame(width: max(abs(x - mid), 0), height: 4)
                    .offset(x: min(x, mid))

                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .frame(width: knob, height: knob)
                    .scaleEffect(dragging ? 1.15 : 1)
                    .offset(x: x - knob / 2)
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !dragging { withAnimation(.snappy(duration: 0.15)) { dragging = true } }
                        var v = Float((gesture.location.x - 2 - knob / 2) / usable) * 2 - 1
                        v = min(max(v, -1), 1)
                        if abs(v) < 0.06 { v = 0 }
                        value = v
                    }
                    .onEnded { _ in withAnimation(.snappy(duration: 0.2)) { dragging = false } }
            )
        }
        .frame(height: height)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.9), value: value)
    }
}

/// Horizontal logo for the footer: bars plus wordmark in quiet gray, slightly embossed.
struct BrandLogo: View {
    var height: CGFloat = 12

    private static func image(_ name: String) -> NSImage? {
        Bundle.main.url(forResource: name, withExtension: "png").flatMap(NSImage.init(contentsOf:))
    }

    private static let mark = image("BrandMark")
    private static let word = image("Wordmark")

    var body: some View {
        if let mark = Self.mark, let word = Self.word {
            // The wordmark image includes the "q" descender (23% of its height) below the baseline.
            HStack(alignment: .bottom, spacing: height * 0.35) {
                template(mark)
                    .frame(height: height * 0.85)
                    .padding(.bottom, height * 0.23)
                template(word)
                    .frame(height: height)
            }
            .foregroundStyle(.tertiary)
            .shadow(color: .white.opacity(0.12), radius: 0, x: 0, y: 0.75)
            .shadow(color: .black.opacity(0.45), radius: 0, x: 0, y: -0.5)
        } else {
            Text("Soniq").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary)
        }
    }

    private func template(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
    }
}

/// Small circular glass icon button.
struct RoundButton: View {
    let symbol: String
    var size: CGFloat = 26
    var active = false
    var help: String = ""
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            RoundIcon(symbol: symbol, size: size, active: active, hovering: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help)
    }
}

struct RoundIcon: View {
    let symbol: String
    var size: CGFloat = 26
    var active = false
    var hovering = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(active ? Color.black.opacity(0.75) : (hovering ? Color.primary : Color.secondary))
            .frame(width: size, height: size)
            .background {
                if active {
                    Circle().fill(Color.white)
                } else {
                    Circle().fill(Color.primary.opacity(hovering ? 0.13 : 0.07))
                }
            }
            .contentShape(Circle())
    }
}

extension View {
    /// Liquid Glass card on macOS 26, translucent card on earlier systems.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            fallbackCard(cornerRadius: cornerRadius)
        }
        #else
        fallbackCard(cornerRadius: cornerRadius)
        #endif
    }

    @ViewBuilder
    func glassCapsule() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: .capsule)
        } else {
            background(Capsule().fill(.ultraThinMaterial))
        }
        #else
        background(Capsule().fill(.ultraThinMaterial))
        #endif
    }

    /// Recessed Liquid Glass track on macOS 26.
    @ViewBuilder
    func glassTrack() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            glassEffect(.regular.tint(Color.black.opacity(0.35)), in: .capsule)
        } else {
            self
        }
        #else
        self
        #endif
    }

    private func fallbackCard(cornerRadius: CGFloat) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}
