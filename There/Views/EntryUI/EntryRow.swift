import SwiftUI

struct EntryRow: View {
    let entry: Entry
    @State private var isHovered: Bool = false
    @Environment(\.colorScheme) var scheme
    @EnvironmentObject var router: Router
    var currentDate: Date = Date()
    @Binding var timeOffset: Double

    var body: some View {
        HStack {
            EntryIcon(entry: entry, date: currentDate.addingTimeInterval(timeOffset * 3600))
            VStack(alignment: .leading) {
                Text(entry.name.isEmpty ? entry.city : entry.name)
                    .font(.title3)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(entry.city)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.leading, 6)
            Spacer()
            VStack(alignment: .trailing) {
                HStack(spacing: 0) {
                    Text(formattedTime(timeZoneIdentifier: entry.timezoneIdentifier))
                        .monospaced()
                        .font(.body)
                        .contentTransition(.numericText())
                }
                Text(formatTimeDifference())
                    .monospaced()
                    .font(.callout)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? scheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.6) : Color.clear)
        .cornerRadius(8)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
        .onTapGesture {
            router.setActiveRoute(to: .editTimeZone(entryId: entry.id))
        }
    }

    private func formattedTime(timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier)

        // Get the system's locale
        let locale = Locale.current

        // Create a template that includes both 24-hour and 12-hour formats
        let template = "j:mm"

        // Generate the best format for the current locale
        if let formatString = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale) {
            formatter.dateFormat = formatString
        } else {
            // Fallback to a default format if generation fails
            formatter.timeStyle = .short
        }
        let offsetDate = currentDate.addingTimeInterval(timeOffset * 3600)

        return formatter.string(from: offsetDate)
    }

    private func formatTimeDifference() -> String {
        let date = currentDate.addingTimeInterval(timeOffset * 3600)
        let seconds = entry.offsetDifference(at: date)
        if seconds == 0 { return "same time" }
        return String(format: "%+.2f hrs", Double(seconds) / 3600)
    }
}
