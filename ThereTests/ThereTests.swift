//
//  ThereTests.swift
//  ThereTests
//
//  Created by Dena Sohrabi on 9/2/24.
//

import Foundation
import Testing
@testable import There

struct ThereTests {

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

    @Test func tiboIsSuggestedBeforeCityResults() {
        #expect(SearchCompleter().results.first == .tibo)
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

