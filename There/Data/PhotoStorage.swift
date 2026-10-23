import AppKit
import Foundation

/// Saves new avatars without touching the previous file until the database write succeeds.
struct PhotoStorage {
    let directory: URL

    init(directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]) {
        self.directory = directory
    }

    func save(_ image: NSImage?) throws -> String? {
        guard let image else { return nil }
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            throw AppDatabase.ValidationError.invalidPhoto
        }
        let photos = directory.appendingPathComponent("Photos", isDirectory: true)
        try FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
        let url = photos.appendingPathComponent(UUID().uuidString + ".png")
        try png.write(to: url, options: .atomic)
        return url.absoluteString
    }

    func remove(_ path: String?) {
        guard let path, let url = URL(string: path), url.isFileURL,
              url.pathExtension.lowercased() == "png",
              UUID(uuidString: url.deletingPathExtension().lastPathComponent) != nil else { return }
        let parent = url.deletingLastPathComponent().standardizedFileURL
        guard parent == directory.standardizedFileURL ||
                parent == directory.appendingPathComponent("Photos").standardizedFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

extension AppDatabase {
    func saveEntry(_ entry: Entry, image: NSImage?, photos: PhotoStorage = PhotoStorage()) throws {
        guard TimeZone(identifier: entry.timezoneIdentifier) != nil else {
            throw ValidationError.invalidTimeZone
        }
        let photoPath = try photos.save(image)
        var updated = entry
        updated.photoData = photoPath
        let savedEntry = updated
        do {
            let previousPath = try dbWriter.write { db in
                let previous = try Entry.fetchOne(db, id: entry.id)?.photoData
                try savedEntry.save(db)
                return previous
            }
            if previousPath != photoPath { photos.remove(previousPath) }
        } catch {
            photos.remove(photoPath)
            throw error
        }
    }
}
