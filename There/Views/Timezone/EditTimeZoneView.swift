import CoreLocation
import MapKit
import SwiftUI

struct EditTimeZoneView: View {
    var entryId: Int64?
    @Environment(\.database) var database
    @StateObject private var searchCompleter = SearchCompleter()
    @EnvironmentObject var router: Router

    @State var entry: Entry?
    @State var image: NSImage?
    @State var name = ""
    @State var city = ""
    @State var selectedTimeZone: TimeZone?
    @State var isShowingPopover = false

    @State var showingXAccountInput = false
    @State var showingTGAccountInput = false

    @State var isLoading = true
    @State var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Titlebar()

            if isLoading {
                Spacer()
                ProgressView()
                    .controlSize(.small)
                Spacer()
            } else if entry != nil {
                ScrollView(.vertical) {
                    VStack(spacing: 12) {
                        IconSection(
                            image: $image,
                            showingXAccountInput: $showingXAccountInput,
                            showingTGAccountInput: $showingTGAccountInput
                        )

                        FormSection(
                            name: $name,
                            city: $city,
                            selectedTimeZone: $selectedTimeZone,
                            isShowingPopover: $isShowingPopover,
                            searchCompleter: searchCompleter,
                            image: $image,
                            showingTGAccountInput: $showingTGAccountInput,
                            showingXAccountInput: $showingXAccountInput,
                            isEditing: true,
                            saveError: errorMessage,
                            onDelete: deleteEntry,
                            saveEntry: saveEntry
                        )
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
            } else {
                Spacer()
                NotFoundView()
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if entry == nil {
                await loadEntry()
            }
        }
    }

    @MainActor
    private func loadEntry() async {
        isLoading = true
        defer { isLoading = false }
        guard let id = entryId else { return }
        do {
            let fetched = try await database.reader.read { db in
                try Entry.fetchOne(db, id: id)
            }
            entry = fetched
            guard let fetched else { return }
            name = fetched.name
            city = fetched.city
            selectedTimeZone = TimeZone(identifier: fetched.timezoneIdentifier)
            if let path = fetched.photoData, let url = URL(string: path), url.isFileURL {
                image = NSImage(contentsOf: url)
            } else if (fetched.name.caseInsensitiveCompare("Tibo") == .orderedSame || fetched.timezoneIdentifier == "Etc/GMT+8"), let tiboAsset = NSImage(named: "tibo") {
                image = tiboAsset
            } else {
                image = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EditTimeZoneView(entryId: 1712)
        .frame(width: 320, height: 440)
        .environment(\.database, .shared)
        .environmentObject(Router())
}
