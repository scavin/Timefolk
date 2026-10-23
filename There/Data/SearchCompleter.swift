import Combine
import Foundation
import MapKit

class TimeZoneSearchCompiler: NSObject {
    private var commonAbbreviations: [String: (fullName: String, identifier: String)]
    private var utcOffsets: [String: String]
    private var activeSearch: MKLocalSearch?

    override init() {
        // Initialize common abbreviations
        commonAbbreviations = [
            // North America
            "EST": ("Eastern Standard Time", "America/New_York"),
            "EDT": ("Eastern Daylight Time", "America/New_York"),
            "CST": ("Central Standard Time", "America/Chicago"),
            "CDT": ("Central Daylight Time", "America/Chicago"),
            "MST": ("Mountain Standard Time", "America/Denver"),
            "MDT": ("Mountain Daylight Time", "America/Denver"),
            "PST": ("Pacific Standard Time", "America/Los_Angeles"),
            "PDT": ("Pacific Daylight Time", "America/Los_Angeles"),
            "AKST": ("Alaska Standard Time", "America/Anchorage"),
            "AKDT": ("Alaska Daylight Time", "America/Anchorage"),
            "HST": ("Hawaii Standard Time", "Pacific/Honolulu"),

            // Europe
            "GMT": ("Greenwich Mean Time", "Etc/GMT"),
            "BST": ("British Summer Time", "Europe/London"),
            "CET": ("Central European Time", "Europe/Paris"),
            "CEST": ("Central European Summer Time", "Europe/Paris"),

            // Asia
            "IST": ("India Standard Time", "Asia/Kolkata"),
            "JST": ("Japan Standard Time", "Asia/Tokyo"),

            // Australia
            "AEST": ("Australian Eastern Standard Time", "Australia/Sydney"),
            "AEDT": ("Australian Eastern Daylight Time", "Australia/Sydney"),

            // Coordinated Universal Time
            "UTC": ("Coordinated Universal Time", "Etc/UTC"),
        ]

        // Initialize UTC offsets
        utcOffsets = [
            "UTC+0": "Etc/GMT",
            "UTC-1": "Etc/GMT+1",
            "UTC-2": "Etc/GMT+2",
            "UTC-3": "Etc/GMT+3",
            "UTC-4": "Etc/GMT+4",
            "UTC-5": "Etc/GMT+5",
            "UTC-6": "Etc/GMT+6",
            "UTC-7": "Etc/GMT+7",
            "UTC-8": "Etc/GMT+8",
            "UTC-9": "Etc/GMT+9",
            "UTC-10": "Etc/GMT+10",
            "UTC-11": "Etc/GMT+11",
            "UTC-12": "Etc/GMT+12",
            "UTC+1": "Etc/GMT-1",
            "UTC+2": "Etc/GMT-2",
            "UTC+3": "Etc/GMT-3",
            "UTC+4": "Etc/GMT-4",
            "UTC+5": "Etc/GMT-5",
            "UTC+5:30": "Asia/Kolkata",
            "UTC+6": "Etc/GMT-6",
            "UTC+7": "Etc/GMT-7",
            "UTC+8": "Etc/GMT-8",
            "UTC+9": "Etc/GMT-9",
            "UTC+10": "Etc/GMT-10",
            "UTC+11": "Etc/GMT-11",
            "UTC+12": "Etc/GMT-12",
            "UTC+13": "Etc/GMT-13",
            "UTC+14": "Etc/GMT-14",
        ]

        super.init()
    }

    func search(query: String, completion: @escaping ([TimeZoneSearchResult]) -> Void) {
        activeSearch?.cancel()
        activeSearch = nil
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { completion([]); return }
        let results = searchPresets(query: query) + searchAbbreviations(query: query) + searchUTCOffsets(query: query) + searchIdentifiers(query: query)

        if !results.isEmpty {
            completion(results)
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address
        

        let search = MKLocalSearch(request: request)
        activeSearch = search
        search.start { [weak self] response, _ in
            guard let self = self, let response = response else {
                completion([])
                return
            }

            let results = self.processResults(response.mapItems)
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }

    private func processResults(_ mapItems: [MKMapItem]) -> [TimeZoneSearchResult] {
        return mapItems.compactMap { item in
//            guard let placemark = item.placemark else { return nil }
            let placemark = item.placemark
            

            let city = placemark.locality ?? placemark.name ?? ""
            let country = placemark.country ?? ""
            // placemark.administrativeArea,
            let subtitle = [country].compactMap { $0 }.joined(separator: ", ")


            
            return TimeZoneSearchResult(
                title: city,
                subtitle: subtitle,
                identifier: placemark.timeZone?.identifier,
                type: .city,
                region: placemark.region,
                coordinate: placemark.location,
                countryCode: placemark.isoCountryCode
            )
        }
    }

    private func searchPresets(query: String) -> [TimeZoneSearchResult] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let keywords = ["Tibo time zone", "Tibo 时区", "Codex reset", "PST"]
        return keywords.contains { $0.localizedCaseInsensitiveContains(query) } ? [.tibo] : []
    }

    private func searchAbbreviations(query: String) -> [TimeZoneSearchResult] {
        return commonAbbreviations
            .filter { $0.key.lowercased().contains(query.lowercased()) }
            .sorted { $0.key < $1.key }
            .map { TimeZoneSearchResult(title: $0.key, subtitle: $0.value.fullName, identifier: $0.value.identifier, type: .abbreviation, region: nil, coordinate: nil) }
    }

    private func searchUTCOffsets(query: String) -> [TimeZoneSearchResult] {
        let normalized = query.uppercased().replacingOccurrences(of: " ", with: "")
        let pattern = #"^(?:UTC|GMT)([+-])(\d{1,2})(?::([0-5]\d))?$"#
        if let expression = try? NSRegularExpression(pattern: pattern),
           let match = expression.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) {
            func part(_ index: Int) -> String {
                guard let range = Range(match.range(at: index), in: normalized) else { return "" }
                return String(normalized[range])
            }
            let sign = part(1) == "+" ? 1 : -1
            let seconds = sign * ((Int(part(2)) ?? 0) * 3600 + (Int(part(3)) ?? 0) * 60)
            guard (-12 * 3600 ... 14 * 3600).contains(seconds),
                  let timezone = TimeZone(secondsFromGMT: seconds) else { return [] }
            return [TimeZoneSearchResult(title: normalized, subtitle: "Fixed UTC offset", identifier: timezone.identifier, type: .utcOffset, region: nil, coordinate: nil)]
        }
        return utcOffsets
            .filter { $0.key.localizedCaseInsensitiveContains(query) }
            .sorted { $0.key < $1.key }
            .map { TimeZoneSearchResult(title: $0.key, subtitle: "Fixed UTC offset", identifier: $0.value, type: .utcOffset, region: nil, coordinate: nil) }
    }

    private func searchIdentifiers(query: String) -> [TimeZoneSearchResult] {
        TimeZone.knownTimeZoneIdentifiers.filter {
            $0.replacingOccurrences(of: "_", with: " ").localizedCaseInsensitiveContains(query)
        }.map {
            TimeZoneSearchResult(title: $0.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? $0,
                                 subtitle: $0, identifier: $0, type: .city, region: nil, coordinate: nil)
        }
    }

}

struct TimeZoneSearchResult: Identifiable, Equatable {
    // A fixed offset is intentional: Los Angeles switches to PDT in summer.
    static let tibo = TimeZoneSearchResult(
        title: "Tibo",
        subtitle: "Codex reset · PST (UTC−08:00, year-round)",
        identifier: "Etc/GMT+8",
        type: .preset,
        region: nil,
        coordinate: nil
    )

    static func ==(lhs: TimeZoneSearchResult, rhs: TimeZoneSearchResult) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.identifier == rhs.identifier && lhs.type == rhs.type && lhs.region == rhs.region
    }
    
    let id = UUID()
    let title: String
    let subtitle: String
    let identifier: String?
    let type: TimeZoneSearchResultType
    let region: CLRegion?
    let coordinate: CLLocation?
    var countryCode: String? = nil

    func getTimeZone() async  -> TimeZone? {
        if let identifier, let timezone = TimeZone(identifier: identifier) { return timezone }
        switch type {
        case .city:
            if let coordinate = coordinate {
                
                return await TimeZone.timeZone(for: coordinate)
            }
            if let region = region as? CLCircularRegion {
                let location = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
                return await TimeZone.timeZone(for: location)
            }
            return nil
        case .abbreviation, .utcOffset, .preset:
            return identifier.flatMap { TimeZone(identifier: $0) }
        }
    }
}

enum TimeZoneSearchResultType {
    case city
    case abbreviation
    case utcOffset
    case preset
}

extension TimeZone {
    static func timeZone(for location: CLLocation) async -> TimeZone? {
           let geocoder = CLGeocoder()
           do {
               let placemarks = try await geocoder.reverseGeocodeLocation(location)
               return placemarks.first?.timeZone
           } catch {
               print("Geocoding error: \(error.localizedDescription)")
               return nil
           }
       }
}

class SearchCompleter: ObservableObject {
    @Published var results: [TimeZoneSearchResult] = []
    @Published var queryFragment: String = "" {
        didSet {
            latestSearch = queryFragment
            if queryFragment.isEmpty {
                results = defaultResults
            } else {
                updateResults(for: queryFragment)
            }
        }
    }

    private let timeZoneSearchCompiler: TimeZoneSearchCompiler
    private var defaultResults: [TimeZoneSearchResult] = []

    init() {
        timeZoneSearchCompiler = TimeZoneSearchCompiler()
        setupDefaultResults()
    }

    private func setupDefaultResults() {
        defaultResults.append(.tibo)

        // All timezones and locations
        for identifier in TimeZone.knownTimeZoneIdentifiers {
            let components = identifier.split(separator: "/")
            if components.count >= 2 {
                let location = String(components.last!).replacingOccurrences(of: "_", with: " ")
                let region = String(components.first!)
                defaultResults.append(TimeZoneSearchResult(title: location, subtitle: region, identifier: identifier, type: .city, region: nil, coordinate: nil))
            }
        }

        // Add UTC offsets
        for offset in -12 ... 14 {
            let sign = offset >= 0 ? "+" : ""
            let title = "UTC\(sign)\(offset)"
            let identifier = "Etc/GMT\(offset == 0 ? "" : (offset > 0 ? "-" : "+") + "\(abs(offset))")"
            defaultResults.append(TimeZoneSearchResult(title: title, subtitle: "Coordinated Universal Time Offset", identifier: identifier, type: .utcOffset, region: nil, coordinate: nil))
        }

        results = defaultResults
    }

    private var latestSearch = ""

    private func updateResults(for query: String) {
        latestSearch = query

        if query.isEmpty {
            results = defaultResults
        } else {
            timeZoneSearchCompiler.search(query: query) { [weak self] searchResults in
                DispatchQueue.main.async {
                    if self?.latestSearch == query {
                        self?.results = searchResults
                    } else {
                        // discard
                    }
                }
            }
        }
    }
}
