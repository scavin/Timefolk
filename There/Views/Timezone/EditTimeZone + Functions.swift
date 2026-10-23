import AppKit
import Foundation

extension EditTimeZoneView {
    func saveEntry() {
        guard let entry else { return }
        do {
            let updated = Entry(
                id: entry.id,
                type: !countryEmoji.isEmpty && image == nil ? .place : .person,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city,
                timezoneIdentifier: selectedTimeZone?.identifier ?? "",
                flag: image == nil ? countryEmoji : nil
            )
            try database.saveEntry(updated, image: image)
            router.cleanActiveRoute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
