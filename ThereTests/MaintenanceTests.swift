import AppKit
import Foundation
import GRDB
import Testing
@testable import Timefolk

@MainActor
struct MaintenanceTests {
    @Test func knownCityResolvesWithoutCoordinates() async throws {
        let result = TimeZoneSearchResult(title: "London", subtitle: "Europe", identifier: "Europe/London", type: .city, region: nil, coordinate: nil)
        #expect(await result.getTimeZone()?.identifier == "Europe/London")
    }

    @Test(arguments: [("UTC+05:45", 20700), ("UTC-03:30", -12600), ("UTC+14", 50400), ("UTC-12", -43200)])
    func fixedOffsetsKeepMinutes(query: String, seconds: Int) async throws {
        var results: [TimeZoneSearchResult] = []
        TimeZoneSearchCompiler().search(query: query) { results = $0 }
        let timezone = try #require(await results.first?.getTimeZone())
        #expect(timezone.secondsFromGMT() == seconds)
        #expect(TimeZone(identifier: timezone.identifier)?.secondsFromGMT() == seconds)
    }

    @Test func clearingSearchDiscardsQueuedResults() async {
        let search = SearchCompleter()
        search.queryFragment = "Tibo"
        search.queryFragment = ""
        // Drain the queued completion from the first query.
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(search.results.count > 1)
        #expect(search.results.first?.identifier == "Africa/Abidjan")
    }

    @Test func minuteOffsetsAndDaylightSavingUseRequestedDate() throws {
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let formatter = ISO8601DateFormatter()
        let winter = try #require(formatter.date(from: "2026-01-15T12:00:00Z"))
        let summer = try #require(formatter.date(from: "2026-07-15T12:00:00Z"))
        let nepal = entry(timezone: "Asia/Kathmandu")
        #expect(nepal.offsetDifference(at: winter, relativeTo: utc) == 20700)
        let la = entry(timezone: "America/Los_Angeles")
        #expect(la.offsetDifference(at: winter, relativeTo: utc) == -28800)
        #expect(la.offsetDifference(at: summer, relativeTo: utc) == -25200)
        #expect(la.dayPeriod(at: winter) == .night)
        #expect(la.dayPeriod(at: summer) == .earlyMorning)
    }

    @Test func editingWithoutPhotoKeepsNilAndPreservesRecordID() throws {
        let database = AppDatabase.empty()
        var original = entry()
        try database.saveEntry(original, image: nil)
        original.name = "Updated"
        try database.saveEntry(original, image: nil)
        let saved = try database.reader.read { db in try Entry.fetchOne(db, id: original.id) }
        #expect(saved?.id == original.id)
        #expect(saved?.name == "Updated")
        #expect(saved?.photoData == nil)
        #expect(try database.reader.read { try Entry.fetchCount($0) } == 1)
    }

    @Test func legacyDatabaseKeepsExistingEntries() throws {
        let queue = try DatabaseQueue()
        try queue.write { db in
            try db.execute(sql: """
                CREATE TABLE grdb_migrations (identifier TEXT NOT NULL PRIMARY KEY);
                INSERT INTO grdb_migrations VALUES ('add entry');
                CREATE TABLE entry (id INTEGER PRIMARY KEY NOT NULL, type TEXT NOT NULL,
                    name TEXT NOT NULL, city TEXT NOT NULL, timezoneIdentifier TEXT NOT NULL,
                    flag TEXT, photoData TEXT);
                INSERT INTO entry VALUES (42, 'person', 'Existing friend', 'London', 'Europe/London', NULL, NULL);
                """)
        }
        let database = try AppDatabase(queue)
        let preserved = try database.reader.read { try Entry.fetchOne($0, id: 42) }
        #expect(preserved?.name == "Existing friend")
        #expect(preserved?.timezoneIdentifier == "Europe/London")
    }

    @Test func invalidTimezoneCannotBeSaved() throws {
        let database = AppDatabase.empty()
        #expect(throws: AppDatabase.ValidationError.self) {
            try database.saveEntry(entry(timezone: "not/a/timezone"), image: nil)
        }
        #expect(try database.reader.read { try Entry.fetchCount($0) } == 0)
    }

    @Test func failedDatabaseWritePreservesPhotoAndCleansNewFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let photos = PhotoStorage(directory: directory)
        let database = AppDatabase.empty()
        let original = entry()
        let photo = NSImage(size: NSSize(width: 2, height: 2), flipped: false) { rect in
            NSColor.red.setFill()
            rect.fill()
            return true
        }
        try database.saveEntry(original, image: photo, photos: photos)
        let path = try #require(database.reader.read { try Entry.fetchOne($0, id: original.id)?.photoData })
        try database.dbWriter.write { db in
            try db.execute(sql: "CREATE TRIGGER reject_update BEFORE UPDATE ON entry BEGIN SELECT RAISE(ABORT, 'Test failure'); END")
        }
        #expect(throws: (any Error).self) {
            try database.saveEntry(original, image: photo, photos: photos)
        }
        #expect(FileManager.default.fileExists(atPath: try #require(URL(string: path)).path))
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.appendingPathComponent("Photos").path).count == 1)
        #expect(try database.reader.read { try Entry.fetchOne($0, id: original.id)?.photoData } == path)
    }

    @Test func removingAvatarDeletesItsFileOnlyAfterSave() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let photos = PhotoStorage(directory: directory)
        let database = AppDatabase.empty()
        let original = entry()
        let photo = NSImage(size: NSSize(width: 2, height: 2), flipped: false) { rect in
            NSColor.blue.setFill()
            rect.fill()
            return true
        }
        try database.saveEntry(original, image: photo, photos: photos)
        let path = try #require(database.reader.read { try Entry.fetchOne($0, id: original.id)?.photoData })
        try database.saveEntry(original, image: nil, photos: photos)
        #expect(try database.reader.read { try Entry.fetchOne($0, id: original.id)?.photoData } == nil)
        #expect(!FileManager.default.fileExists(atPath: try #require(URL(string: path)).path))
    }

    private func entry(timezone: String = "Etc/GMT+8") -> Entry {
        Entry(type: .person, name: "Tibo", city: "PST", timezoneIdentifier: timezone)
    }
}
