import SwiftUI

struct AddButton: View {
    @State private var addHovered: Bool = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: Router

    var body: some View {
        CompactButton(title: "添加") {
            router.setActiveRoute(to: .addTimezone)
        }
        .accessibilityIdentifier("timezone.add")
    }
}

#Preview {
    AddButton()
        .padding()
}
