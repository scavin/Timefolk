import SwiftUI

struct StyledLabel: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
    }
}

#Preview {
    StyledLabel(title: "Name")
}
