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
                    }
                }
            }
        }
    }

    func saveEntry() {
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let isPlace = image == nil && (trimmedName.isEmpty || trimmedName == city)
            let entry = Entry(
                type: isPlace ? .place : .person,
                name: trimmedName,
                city: city,
                timezoneIdentifier: selectedTimeZone?.identifier ?? "",
                flag: nil
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
        selectedTimeZone = nil
    }

}
