//
//  ThereTests.swift
//  ThereTests
//
//  Created by Dena Sohrabi on 9/2/24.
//

import AppKit
import Foundation
import GRDB
import Testing
@testable import Timefolk

struct ThereTests {

    @Test func tiboDedicatedAvatarAssetLoads() {
        let image = NSImage(named: "tibo")
        #expect(image != nil)
        #expect((image?.size.width ?? 0) > 0)
    }

    @Test func tiboUsesFixedPSTAcrossSeasons() async throws {
        let timezone = try #require(await TimeZoneSearchResult.tibo.getTimeZone())
        let formatter = ISO8601DateFormatter()
        for timestamp in ["2026-01-15T18:00:00Z", "2026-07-15T18:00:00Z"] {
            let date = try #require(formatter.date(from: timestamp))
            #expect(timezone.secondsFromGMT(for: date) == -8 * 3600)
            #expect(!timezone.isDaylightSavingTime(for: date))

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timezone
            #expect(calendar.component(.hour, from: date) == 10)

            // The saved identifier must retain the fixed offset after reopening.
            let restored = try #require(TimeZone(identifier: timezone.identifier))
            #expect(restored.secondsFromGMT(for: date) == -8 * 3600)
        }
    }

    @Test func tiboIsSeededAsDefaultEntry() throws {
        let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        let db = try AppDatabase(dbQueue)
        let testDefaults = UserDefaults(suiteName: "TestSuit-\(UUID().uuidString)")!
        AppDatabase.seedDefaultEntriesIfNeeded(in: db.dbWriter, userDefaults: testDefaults)

        let entries = try db.dbWriter.read { try Entry.fetchAll($0) }
        #expect(entries.count == 1)
        #expect(entries.first?.name == "Tibo")
        #expect(entries.first?.timezoneIdentifier == "Etc/GMT+8")
    }

    @Test func tiboIsNotReseededWhenUserDeletesAllEntries() throws {
        let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        let db = try AppDatabase(dbQueue)
        let testDefaults = UserDefaults(suiteName: "TestSuit-\(UUID().uuidString)")!

        // First launch: seeds Tibo
        AppDatabase.seedDefaultEntriesIfNeeded(in: db.dbWriter, userDefaults: testDefaults, force: true)
        let initialEntries = try db.dbWriter.read { try Entry.fetchAll($0) }
        #expect(initialEntries.count == 1)

        // User intentionally deletes all entries
        try db.dbWriter.write { try Entry.deleteAll($0) }
        let countAfterDelete = try db.dbWriter.read { try Entry.fetchCount($0) }
        #expect(countAfterDelete == 0)

        // Mark that defaults were seeded
        testDefaults.set(true, forKey: "hasSeededDefaultEntries")

        // Second launch: should NOT re-seed Tibo
        AppDatabase.seedDefaultEntriesIfNeeded(in: db.dbWriter, userDefaults: testDefaults)
        let finalEntries = try db.dbWriter.read { try Entry.fetchAll($0) }
        #expect(finalEntries.count == 0)
    }

    @Test(arguments: ["Tibo", "tIbO", "Codex", "reset", "PST"])
    func tiboCanBeFoundWithoutGeocoding(query: String) {
        var results: [TimeZoneSearchResult] = []
        TimeZoneSearchCompiler().search(query: query) { results = $0 }
        #expect(results.first == .tibo)

        if query == "PST" {
            // Keep the existing regional option available alongside the preset.
            #expect(results.contains { $0.identifier == "America/Los_Angeles" })
        }
    }
}

