import SwiftUI

struct EmptyTimezoneView: View {
    @EnvironmentObject var router: Router
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.18),
                                Color.accentColor.opacity(0.02)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 130, height: 130)

                Image("Earth")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 100)
            }
            .padding(.bottom, 2)

            VStack(spacing: 4) {
                Text("暂无时区")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text("添加身在各地的朋友，\n一眼看清他们的作息。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {
                withAnimation(TimefolkTheme.Animation.quick) {
                    router.setActiveRoute(to: .addTimezone)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("添加朋友")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 0.5)
                )
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(24)
    }
}

#Preview {
    EmptyTimezoneView()
        .frame(width: 320, height: 360)
        .environmentObject(Router())
}
