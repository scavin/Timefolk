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
    @State var countryEmoji = ""

    @State var showingXAccountInput = false
    @State var showingTGAccountInput = false

    @State var isLoading = true
    @State var errorMessage: String?

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if isLoading {
                ProgressView()
            } else if entry != nil {
                IconSection(
                    image: $image,
                    countryEmoji: $countryEmoji,
                    showingXAccountInput: $showingXAccountInput,
                    showingTGAccountInput: $showingTGAccountInput
                )

                FormSection(
                    name: $name,
                    city: $city,
                    selectedTimeZone: $selectedTimeZone,
                    isShowingPopover: $isShowingPopover,
                    searchCompleter: searchCompleter,
                    countryEmoji: $countryEmoji,
                    image: $image,
                    showingTGAccountInput: $showingTGAccountInput,
                    showingXAccountInput: $showingXAccountInput,
                    isEditing: true,
                    saveError: errorMessage,
                    saveEntry: saveEntry
                )
            } else {
                NotFoundView()
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            Titlebar()
                .padding(6)
        }
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
            countryEmoji = fetched.flag ?? ""
            if let path = fetched.photoData, let url = URL(string: path), url.isFileURL {
                image = NSImage(contentsOf: url)
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
        .frame(width: 300, height: 400)
        .environment(\.database, .shared)
}
