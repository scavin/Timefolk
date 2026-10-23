import AppKit
import Foundation

enum CalendarEventHelper {
    static func createAndOpenEvent(
        title: String,
        startDate: Date,
        durationMinutes: Int = 30,
        location: String? = nil,
        note: String? = nil
    ) {
        let endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"

        let dtStamp = formatter.string(from: Date())
        let dtStart = formatter.string(from: startDate)
        let dtEnd = formatter.string(from: endDate)
        let uid = UUID().uuidString

        var ics = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Timefolk//Timefolk Calendar Export//CN",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            "BEGIN:VEVENT",
            "UID:\(uid)",
            "DTSTAMP:\(dtStamp)",
            "DTSTART:\(dtStart)",
            "DTEND:\(dtEnd)",
            "SUMMARY:\(escapeICS(title))"
        ]

        if let location = location, !location.isEmpty {
            ics.append("LOCATION:\(escapeICS(location))")
        }
        if let note = note, !note.isEmpty {
            ics.append("DESCRIPTION:\(escapeICS(note))")
        }

        ics.append("END:VEVENT")
        ics.append("END:VCALENDAR")

        let content = ics.joined(separator: "\r\n")

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("timefolk-event-\(uid).ics")
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(tempURL)
        } catch {
            print("Failed to open calendar event: \(error)")
        }
    }

    private static func escapeICS(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
