import SwiftUI

struct SettingsButton: View {
    @State private var settingsHovered: Bool = false
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: Router
    @Environment(\.database) var database: AppDatabase
    @Environment(\.colorScheme) var scheme
    @AppStorage("use24HourFormat") private var use24HourFormat: Bool = false
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var updatingLoginItem = false
    @State private var loginItemError: String?
    @Binding var sortOrder: SortOrder

    var body: some View {
        Menu {
            Toggle("开机启动", isOn: Binding(
                get: { launchAtLogin },
                set: { enabled in
                    updatingLoginItem = true
                    Task { @MainActor in
                        defer {
                            launchAtLogin = LoginItem.isEnabled
                            updatingLoginItem = false
                        }
                        do {
                            try await LoginItem.setEnabled(enabled)
                        } catch {
                            loginItemError = error.localizedDescription
                        }
                    }
                }
            ))
            .disabled(updatingLoginItem)

            Divider()

            Toggle("24 小时制", isOn: $use24HourFormat)

            Divider()

            Picker("时区排序", selection: $sortOrder) {
                Text("由早到晚").tag(SortOrder.timeAscending)
                Text("由晚到早").tag(SortOrder.timeDescending)
            }

            Section {
                Button("关于 Timefolk") {
                    router.setActiveRoute(to: .about)
                }
            }

            Divider()

            Button("退出程序") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 13, weight: .medium))
        }
        .buttonStyle(SettingsButtonStyle())
        .onAppear { launchAtLogin = LoginItem.isEnabled }
        .alert("设置失败", isPresented: Binding(
            get: { loginItemError != nil },
            set: { if !$0 { loginItemError = nil } }
        )) {
            Button("好") { loginItemError = nil }
        } message: {
            Text(loginItemError ?? "")
        }
    }
}

#Preview {
    SettingsButton(sortOrder: .constant(.timeAscending))
        .environmentObject(AppState())
        .environmentObject(Router())
}

struct SettingsButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @State private var isHovered = false
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isActive ? .white : (isHovered ? .primary : .secondary))
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                    .fill(
                        isActive
                            ? Color.accentColor
                            : (isHovered
                                ? TimefolkTheme.Colors.cardHoverBackground(colorScheme: scheme)
                                : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                    .strokeBorder(
                        isActive
                            ? Color.white.opacity(scheme == .dark ? 0.25 : 0)
                            : (isHovered
                                ? TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme)
                                : Color.clear),
                        lineWidth: 0.5
                    )
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(TimefolkTheme.Animation.quick, value: configuration.isPressed)
            .animation(TimefolkTheme.Animation.quick, value: isHovered)
            .animation(TimefolkTheme.Animation.quick, value: isActive)
            .onHover { hovering in
                self.isHovered = hovering
            }
    }
}
