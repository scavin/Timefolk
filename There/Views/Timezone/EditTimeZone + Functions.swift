import AppKit
import Foundation
import SwiftUI

extension EditTimeZoneView {
    func saveEntry() {
        guard let entry else { return }
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let isPlace = image == nil && (trimmedName.isEmpty || trimmedName == city)
            let updated = Entry(
                id: entry.id,
                type: isPlace ? .place : .person,
                name: trimmedName,
                city: city,
                timezoneIdentifier: selectedTimeZone?.identifier ?? "",
                flag: nil,
                photoData: image == nil ? nil : entry.photoData
            )
            try database.saveEntry(updated, image: image)
            router.cleanActiveRoute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEntry() {
        guard let entry else { return }
        Task {
            do {
                try await database.dbWriter.write { db in
                    let fetched = try Entry.fetchOne(db, id: entry.id)
                    try fetched?.delete(db)
                }
                PhotoStorage().remove(entry.photoData)
                await MainActor.run {
                    withAnimation(TimefolkTheme.Animation.quick) {
                        router.cleanActiveRoute()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
