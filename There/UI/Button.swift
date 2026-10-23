import SwiftUI

// MARK: - PrimaryButton
struct PrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isEnabled ? Color.white : (scheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.3)))
            .shadow(color: isEnabled ? Color.black.opacity(scheme == .dark ? 0.45 : 0.15) : .clear, radius: 0.5, x: 0, y: 0.8)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                ZStack {
                    if isEnabled {
                        RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: scheme == .dark
                                        ? [
                                            Color(nsColor: .controlAccentColor),
                                            Color(nsColor: .controlAccentColor).opacity(hovered ? 0.95 : 0.88)
                                        ]
                                        : [
                                            Color.accentColor.opacity(hovered ? 0.95 : 0.9),
                                            Color.accentColor
                                        ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        // 2026 原生 macOS 顶部超细微高光与内边框
                        RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                            .strokeBorder(Color.white.opacity(scheme == .dark ? 0.28 : 0.35), lineWidth: 0.5)
                    } else {
                        RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                            .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                            .strokeBorder(TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme), lineWidth: 0.5)
                    }
                }
            )
            .shadow(
                color: Color.accentColor.opacity(isEnabled ? (hovered ? 0.4 : 0.22) : 0),
                radius: hovered ? 4 : 2,
                x: 0,
                y: hovered ? 2 : 1
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(TimefolkTheme.Animation.quick, value: configuration.isPressed)
            .animation(TimefolkTheme.Animation.quick, value: hovered)
            .onHover { hovering in
                self.hovered = hovering
            }
    }
}

// MARK: - SecondaryButton
struct SecondaryButton: View {
    var title: String
    var isActive: Bool = false
    var action: () -> Void

    init(title: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(SecondaryButtonStyle(isActive: isActive))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var isActive: Bool = false
    @Environment(\.colorScheme) private var scheme
    @State private var hovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .font(.system(size: 13, weight: isActive ? .semibold : .medium))
            .foregroundColor(isActive ? (scheme == .dark ? .white : .accentColor) : .primary)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                        .fill(
                            isActive
                                ? (scheme == .dark ? Color.accentColor : Color.accentColor.opacity(0.12))
                                : (hovered
                                    ? TimefolkTheme.Colors.cardHoverBackground(colorScheme: scheme)
                                    : TimefolkTheme.Colors.cardBackground(colorScheme: scheme))
                        )
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                        .strokeBorder(
                            isActive
                                ? Color.accentColor.opacity(0.55)
                                : TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme),
                            lineWidth: 0.5
                        )
                }
            )
            .shadow(
                color: Color.black.opacity(hovered ? (scheme == .dark ? 0.3 : 0.06) : 0),
                radius: 2,
                x: 0,
                y: 1
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(TimefolkTheme.Animation.quick, value: configuration.isPressed)
            .animation(TimefolkTheme.Animation.quick, value: hovered)
            .animation(TimefolkTheme.Animation.quick, value: isActive)
            .onHover { hovering in
                self.hovered = hovering
            }
    }
}

// MARK: - CompactButton
struct CompactButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .buttonStyle(CompactButtonStyle())
    }
}

struct CompactButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @State private var hovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .foregroundColor(.primary)
            .frame(height: 28)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                        .fill(
                            hovered
                                ? TimefolkTheme.Colors.cardHoverBackground(colorScheme: scheme)
                                : TimefolkTheme.Colors.cardBackground(colorScheme: scheme)
                        )
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                        .strokeBorder(TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme), lineWidth: 0.5)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(TimefolkTheme.Animation.quick, value: configuration.isPressed)
            .animation(TimefolkTheme.Animation.quick, value: hovered)
            .onHover { hovering in
                self.hovered = hovering
            }
    }
}

// MARK: - CompactPrimaryButton
struct CompactPrimaryButton: View {
    var title: String
    var action: () -> Void
    var width: CGFloat = 232

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(CompactPrimaryButtonStyle(width: width))
    }
}

struct CompactPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @State private var hovered: Bool = false
    var width: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: width, height: 30)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(hovered ? 0.92 : 0.85),
                                    Color.accentColor
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                }
            )
            .shadow(
                color: Color.accentColor.opacity(hovered ? 0.35 : 0.2),
                radius: hovered ? 4 : 2,
                x: 0,
                y: 1
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(TimefolkTheme.Animation.quick, value: configuration.isPressed)
            .animation(TimefolkTheme.Animation.quick, value: hovered)
            .onHover { hovering in
                self.hovered = hovering
            }
    }
}

// MARK: - Preview
struct ButtonPreviews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PrimaryButton(title: "Primary Button", action: {})
            SecondaryButton(title: "Secondary Button", action: {})
            CompactButton(title: "Add", action: {})
            CompactPrimaryButton(title: "Compact Primary Button", action: {})
        }
        .padding()
        .frame(width: 300)
    }
}
