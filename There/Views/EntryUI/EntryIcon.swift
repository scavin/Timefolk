import CoreLocation
import SwiftUI

struct EntryIcon: View {
    let entry: Entry
    var date: Date = Date()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.database) var database

    private var circleBackground: Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: 40, height: 40)

            timePeriodBadge
                .offset(x: 3, y: 3)
        }
        .frame(width: 44, height: 44)
    }

    private var isTibo: Bool {
        entry.name.caseInsensitiveCompare("Tibo") == .orderedSame ||
        (entry.timezoneIdentifier == "Etc/GMT+8" && entry.name.localizedCaseInsensitiveContains("Tibo"))
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let data = entry.photoData, !data.isEmpty {
            photoIcon(data: data)
        } else if isTibo, let tiboImage = NSImage(named: "tibo") {
            tiboAvatar(image: tiboImage)
        } else {
            defaultIcon
        }
    }

    private func tiboAvatar(image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }

    private func photoIcon(data: String) -> some View {
        Group {
            if let url = URL(string: data) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                    case .failure, .empty:
                        defaultIcon
                    @unknown default:
                        defaultIcon
                    }
                }
            } else {
                defaultIcon
            }
        }
    }

    private var defaultIcon: some View {
        Circle()
            .fill(circleBackground)
            .overlay(
                Image(systemName: entry.type == .place ? "mappin.circle.fill" : "person.crop.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(entry.type == .place ? .accentColor : .secondary)
            )
            .overlay(
                Circle()
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
    }

    private var timePeriodBadge: some View {
        ZStack {
            Circle()
                .fill(scheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color.white)
                .frame(width: 17, height: 17)
                .shadow(color: Color.black.opacity(0.2), radius: 1.5, x: 0, y: 1)

            Image(entry.dayPeriod(at: date).rawValue)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
        }
        .overlay(
            Circle()
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
    }
}
