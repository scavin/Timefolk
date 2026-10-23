import CoreLocation
import MapKit
import SwiftUI

struct AddTimezone: View {
    @Environment(\.database) var database
    @StateObject private var searchCompleter = SearchCompleter()
    @EnvironmentObject var router: Router

    @State var image: NSImage?
    @State var name = ""
    @State var city = ""
    @State var errorMessage: String?
    @State var selectedTimeZone: TimeZone? = nil
    @State var isShowingPopover = false

    @State var showingXAccountInput = false
    @State var showingTGAccountInput = false

    var body: some View {
        VStack(spacing: 0) {
            Titlebar()

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
                        saveError: errorMessage,
                        saveEntry: saveEntry
                    )
                }
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AddTimezone()
        .frame(width: 320, height: 440)
        .environmentObject(Router())
}
