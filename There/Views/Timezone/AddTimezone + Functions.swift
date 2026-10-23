import AppKit
import CoreLocation
import Foundation
import MapKit
import SwiftUI

extension AddTimezone {
    func searchPlace(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, _ in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                DispatchQueue.main.async {
                    if let placemark = placemarks?.first {
                        if let timeZone = placemark.timeZone {
                            self.selectedTimeZone = timeZone
                        }
                        self.countryEmoji = Utils.shared.getCountryEmoji(for: placemark.isoCountryCode ?? "")
                    }
                }
            }
        }
    }

    func saveEntry() {
        do {
            let entry = Entry(
                type: !countryEmoji.isEmpty && image == nil ? .place : .person,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city,
                timezoneIdentifier: selectedTimeZone?.identifier ?? "",
                flag: image == nil ? countryEmoji : nil
            )
            try database.saveEntry(entry, image: image)
            router.cleanActiveRoute()
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetForm() {
        image = nil
        name = ""
        city = ""
        showingXAccountInput = false
        showingTGAccountInput = false
        selectedTimeZone = TimeZone.current
        isShowingPopover = false
        countryEmoji = ""
        selectedTimeZone = nil
    }

}
