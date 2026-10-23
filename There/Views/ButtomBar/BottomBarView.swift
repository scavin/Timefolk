import SwiftUI

struct BottomBarView: View {
    @Binding var isAtBottom: Bool
    @Binding var sortOrder: SortOrder
    @Binding var showSlider: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 6) {
            AddButton()

            Spacer()

            Button {
                withAnimation(TimefolkTheme.Animation.smooth) {
                    showSlider.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(SettingsButtonStyle(isActive: showSlider))
            .help("时间穿梭")

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
    BottomBarView(isAtBottom: .constant(true), sortOrder: .constant(.timeDescending), showSlider: .constant(false))
}
