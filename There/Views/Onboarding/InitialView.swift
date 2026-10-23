// InitialView.swift

import SwiftUI

struct InitialView: View {
    @Environment(\.database) var database
    @State private var userName: String = ""
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 60) {
            LeftPanel()
            RightPanel(userName: $userName, saveUser: saveUser)
        }
        .padding(32)
    }

    func saveUser() {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: "userName")
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
        AppDatabase.seedDefaultEntriesIfNeeded(in: database.dbWriter)
    }
}

#Preview {
    InitialView()
        .frame(width: 600, height: 400)
}
