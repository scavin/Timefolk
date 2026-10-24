import SwiftUI

struct AddButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: Router

    var body: some View {
        Button {
            router.setActiveRoute(to: .addTimezone)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .medium))
        }
        .buttonStyle(SettingsButtonStyle())
        .help("添加")
        .accessibilityIdentifier("timezone.add")
        .accessibilityLabel("添加")
    }
}

#Preview {
    AddButton()
        .padding()
}
