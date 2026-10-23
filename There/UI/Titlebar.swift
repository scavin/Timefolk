import SwiftUI

struct Titlebar: View {
    @EnvironmentObject var router: Router
    @Environment(\.colorScheme) private var scheme
    @State private var hovered: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button {
                withAnimation(TimefolkTheme.Animation.quick) {
                    router.cleanActiveRoute()
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 11, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(hovered ? .primary : .secondary)
                .padding(.horizontal, 6)
                .frame(height: 24)
                .background(
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                        .fill(
                            hovered
                                ? TimefolkTheme.Colors.cardHoverBackground(colorScheme: scheme)
                                : Color.clear
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                        .strokeBorder(
                            hovered
                                ? TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme)
                                : Color.clear,
                            lineWidth: 0.5
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回")
            .keyboardShortcut(.cancelAction)
            .onHover { hovering in
                withAnimation(TimefolkTheme.Animation.quick) {
                    self.hovered = hovering
                }
            }

            EmptyView()

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

#Preview {
    Titlebar()
        .padding()
        .environmentObject(Router())
}
