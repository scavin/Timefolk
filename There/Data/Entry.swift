import Foundation
import GRDB
import SwiftUI

enum EntryType: String, Codable, Sendable {
    case place
    case person
}

enum DayPeriod: String, CaseIterable {
    case earlyMorning = "early-morning"
    case lateMorning = "late-morning"
    case earlyAfternoon = "early-afternoon"
    case lateAfternoon = "late-afternoon"
    case earlyEvening = "early-evening"
    case evening
    case night
}

struct Entry: Codable, Equatable, Identifiable, FetchableRecord, PersistableRecord, Sendable {
    let id: Int64
    var type: EntryType
    var name: String
    var city: String
    var timezoneIdentifier: String
    var flag: String?
    var photoData: String?

    enum Columns: String, ColumnExpression {
        case id, type, name, city, country, timezoneIdentifier, flag, photoData
    }

    init(id: Int64 = Int64.random(in: 1 ... Int64.max), type: EntryType, name: String, city: String, timezoneIdentifier: String, flag: String? = nil, photoData: String? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.city = city
        self.timezoneIdentifier = timezoneIdentifier
        self.flag = flag
        self.photoData = photoData
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, type, name, city, timezoneIdentifier, flag, photoData
    }

    func offsetDifference(at date: Date, relativeTo localTimeZone: TimeZone = .current) -> Int {
        guard let timeZone = TimeZone(identifier: timezoneIdentifier) else { return 0 }
        return timeZone.secondsFromGMT(for: date) - localTimeZone.secondsFromGMT(for: date)
    }

    func dayPeriod(at date: Date) -> DayPeriod {
        guard let timeZone = TimeZone(identifier: timezoneIdentifier) else { return .night }
        let hour = Calendar(identifier: .gregorian).dateComponents(in: timeZone, from: date).hour ?? 0
        switch hour {
        case 5 ..< 8: return .earlyMorning
        case 8 ..< 12: return .lateMorning
        case 12 ..< 15: return .earlyAfternoon
        case 15 ..< 17: return .lateAfternoon
        case 17 ..< 19: return .earlyEvening
        case 19 ..< 22: return .evening
        default: return .night
        }
    }

    var timeDifference: (hours: Int, minutes: Int, dayPeriod: DayPeriod) {
        let now = Date()
        let difference = offsetDifference(at: now)
        return (difference / 3600, (difference % 3600) / 60, dayPeriod(at: now))
    }

    var timeIcon: String {
        dayPeriod(at: Date()).rawValue
    }
}
