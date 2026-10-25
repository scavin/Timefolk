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

    @Test func tiboFollowsSeattleDaylightSaving() async throws {
        let timezone = try #require(await TimeZoneSearchResult.tibo.getTimeZone())
        #expect(timezone.identifier == "America/Los_Angeles")

        let formatter = ISO8601DateFormatter()
        let winterDate = try #require(formatter.date(from: "2026-01-15T18:00:00Z"))
        let summerDate = try #require(formatter.date(from: "2026-07-15T18:00:00Z"))

        // Winter: PST (UTC-8)
        #expect(timezone.secondsFromGMT(for: winterDate) == -8 * 3600)
        #expect(!timezone.isDaylightSavingTime(for: winterDate))
        var winterCal = Calendar(identifier: .gregorian)
        winterCal.timeZone = timezone
        #expect(winterCal.component(.hour, from: winterDate) == 10)

        // Summer: PDT (UTC-7)
        #expect(timezone.secondsFromGMT(for: summerDate) == -7 * 3600)
        #expect(timezone.isDaylightSavingTime(for: summerDate))
        var summerCal = Calendar(identifier: .gregorian)
        summerCal.timeZone = timezone
        #expect(summerCal.component(.hour, from: summerDate) == 11)

        // The saved identifier must retain America/Los_Angeles
        let restored = try #require(TimeZone(identifier: timezone.identifier))
        #expect(restored.secondsFromGMT(for: winterDate) == -8 * 3600)
        #expect(restored.secondsFromGMT(for: summerDate) == -7 * 3600)
    }

    @Test func tiboIsSeededAsDefaultEntry() throws {
        let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        let db = try AppDatabase(dbQueue)
        let testDefaults = UserDefaults(suiteName: "TestSuit-\(UUID().uuidString)")!
        AppDatabase.seedDefaultEntriesIfNeeded(in: db.dbWriter, userDefaults: testDefaults)

        let entries = try db.dbWriter.read { try Entry.fetchAll($0) }
        #expect(entries.count == 1)
        #expect(entries.first?.name == "Tibo")
        #expect(entries.first?.city == "Seattle")
        #expect(entries.first?.timezoneIdentifier == "America/Los_Angeles")
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

    @Test(arguments: ["Tibo", "tIbO", "Codex", "reset", "PST", "PDT", "Seattle"])
    func tiboCanBeFoundWithoutGeocoding(query: String) {
        var results: [TimeZoneSearchResult] = []
        TimeZoneSearchCompiler().search(query: query) { results = $0 }
        #expect(results.first == .tibo)

        if query == "PST" {
            // Keep the existing regional option available alongside the preset.
            #expect(results.contains { $0.identifier == "America/Los_Angeles" })
        }
    }

    @Test func timeTravelSnappingNeverProduces59Minutes() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!

        // Test across various second and millisecond values
        for sec in [0, 1, 15, 30, 45, 59] {
            for ms in [0.0, 150.0, 500.0, 999.0] {
                let now = Date(timeIntervalSince1970: 1700000000.0 + Double(sec) + (ms / 1000.0))
                let cleanBaseDate = cal.dateInterval(of: .minute, for: now)?.start ?? now
                let startOfHour = cal.dateInterval(of: .hour, for: cleanBaseDate)?.start ?? cleanBaseDate

                for sliderHour in [-48.0, -1.0, 0.5, 1.0, 8.5, 24.0] {
                    let target = cal.date(byAdding: .minute, value: Int(sliderHour * 60), to: startOfHour) ?? cleanBaseDate
                    let timeOffset = target.timeIntervalSince(cleanBaseDate) / 3600.0

                    let offsetDate = cleanBaseDate.addingTimeInterval(timeOffset * 3600)
                    let minute = cal.component(.minute, from: offsetDate)
                    let second = cal.component(.second, from: offsetDate)

                    #expect(second == 0)
                    #expect(minute == 0 || minute == 30)
                }
            }
        }
    }
}

