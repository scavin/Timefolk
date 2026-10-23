// RightPanel.swift

import SwiftUI

struct RightPanel: View {
    @Binding var userName: String
    let saveUser: () -> Void
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("你的称呼")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("在时钟与时间推演中作为你的标识。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 6)

            Input(text: $userName, placeholder: "比如：阿杰、Alex", icon: "person")

            PrimaryButton(title: "开始使用", action: {
                saveUser()
                appState.presentMenu()
                presentationMode.wrappedValue.dismiss()
            })
            .padding(.top, 4)

            SecondaryButton(title: "稍后设置", action: {
                saveUser()
                appState.presentMenu()
                presentationMode.wrappedValue.dismiss()
            })
        }
        .frame(maxWidth: 240)
    }
}
