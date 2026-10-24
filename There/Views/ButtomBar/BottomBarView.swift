import SwiftUI

struct BottomBarView: View {
    @Binding var isAtBottom: Bool
    @Binding var sortOrder: SortOrder
    @Binding var timeOffset: Double
    var onResetTime: () -> Void = {}
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 6) {
            AddButton()

            Spacer()

            if timeOffset != 0 {
                Button {
                    withAnimation(TimefolkTheme.Animation.quick) {
                        onResetTime()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(SettingsButtonStyle())
                .help("回到此刻")
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            SettingsButton(sortOrder: $sortOrder)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(
            ZStack(alignment: .top) {
                // 原生底部工具栏背景
                Rectangle()
                    .fill(.regularMaterial)
                
                // 微分割线
                Divider()
                    .opacity(0.4)
            }
        )
    }
}

#Preview {
    BottomBarView(isAtBottom: .constant(true), sortOrder: .constant(.timeDescending), timeOffset: .constant(0))
}
