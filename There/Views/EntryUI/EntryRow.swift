import AppKit
import SwiftUI

// MARK: - RightClickable ViewModifier
struct RightClickable: NSViewRepresentable {
    var onRightClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = RightClickNSView()
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? RightClickNSView)?.onRightClick = onRightClick
    }

    class RightClickNSView: NSView {
        var onRightClick: (() -> Void)?

        override func hitTest(_ point: NSPoint) -> NSView? {
            if let event = NSApp.currentEvent, event.type == .rightMouseDown || event.type == .rightMouseUp {
                return self
            }
            return nil
        }

        override func rightMouseDown(with event: NSEvent) {
            onRightClick?()
        }
    }
}

extension View {
    func onRightClick(perform action: @escaping () -> Void) -> some View {
        self.overlay(RightClickable(onRightClick: action))
    }
}

// MARK: - EntryRow
struct EntryRow: View {
    let entry: Entry
    var currentDate: Date = Date()
    @Binding var timeOffset: Double
    var isAnchor: Bool = false
    var showSlider: Bool = false
    var onTap: () -> Void = {}
    var onRightClick: () -> Void = {}
    var onCloseSlider: () -> Void = {}

    @State private var isHovered: Bool = false
    @Environment(\.colorScheme) private var scheme
    @AppStorage("use24HourFormat") private var use24HourFormat: Bool = false
    @AppStorage("userTimezoneIdentifier") private var userTimezoneIdentifier: String = ""

    private var effectiveLocalTimeZone: TimeZone {
        if !userTimezoneIdentifier.isEmpty, let tz = TimeZone(identifier: userTimezoneIdentifier) {
            return tz
        }
        return TimeZone.current
    }

    private var entryDisplayName: String {
        entry.name.isEmpty ? entry.city : entry.name
    }

    private var hasCustomName: Bool {
        let trimmedName = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = entry.city.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.caseInsensitiveCompare(trimmedCity) != .orderedSame
    }

    var body: some View {
        VStack(spacing: 0) {
            // 基本信息栏（点击直接进入时间穿梭，右键直接进入编辑）
            HStack(spacing: 10) {
                EntryIcon(entry: entry, date: currentDate.addingTimeInterval(timeOffset * 3600))

                VStack(alignment: .leading, spacing: 1) {
                    Text(entryDisplayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if hasCustomName {
                        Text(entry.city)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(formattedTime(timeZoneIdentifier: entry.timezoneIdentifier))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    HStack(spacing: 4) {
                        if let dayDiff = relativeDayDifference() {
                            Text(dayDiff)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(
                                    Capsule()
                                        .fill(scheme == .dark ? Color.accentColor : Color.accentColor.opacity(0.15))
                                )
                                .foregroundColor(scheme == .dark ? .white : .accentColor)
                        }

                        if let timeDiff = formatTimeDifference() {
                            Text(timeDiff)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // 当事人那一条的时间穿梭进度条
            if showSlider {
                InlineTimeSlider(
                    timeOffset: $timeOffset,
                    timeZoneIdentifier: entry.timezoneIdentifier,
                    anchorName: entryDisplayName,
                    city: entry.city,
                    currentDate: currentDate,
                    onClose: onCloseSlider
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, showSlider ? 8 : 7)
        .background(
            RoundedRectangle(cornerRadius: TimefolkTheme.Radius.large, style: .continuous)
                .fill(
                    showSlider
                        ? (scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        : (isHovered
                            ? TimefolkTheme.Colors.cardHoverBackground(colorScheme: scheme)
                            : (isAnchor && timeOffset != 0 ? Color.accentColor.opacity(0.04) : Color.clear))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: TimefolkTheme.Radius.large, style: .continuous)
                .strokeBorder(
                    showSlider
                        ? Color.accentColor.opacity(0.38)
                        : (isAnchor && timeOffset != 0
                            ? Color.accentColor.opacity(0.35)
                            : (isHovered ? TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme) : Color.clear)),
                    lineWidth: 0.5
                )
        )
        .contentShape(Rectangle())
        .onRightClick {
            onRightClick()
        }
        .onHover { hovered in
            withAnimation(TimefolkTheme.Animation.quick) {
                self.isHovered = hovered
            }
        }
    }

    private func formattedTime(timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier)

        if use24HourFormat {
            formatter.dateFormat = "HH:mm"
        } else {
            let locale = Locale.current
            let template = "j:mm"
            if let formatString = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale) {
                formatter.dateFormat = formatString
            } else {
                formatter.timeStyle = .short
            }
        }
        var cal = Calendar(identifier: .gregorian)
        if let tz = TimeZone(identifier: timeZoneIdentifier) { cal.timeZone = tz }
        let cleanBaseDate = timeOffset != 0 ? (cal.date(bySetting: .second, value: 0, of: currentDate) ?? currentDate) : currentDate
        let offsetDate = cleanBaseDate.addingTimeInterval(timeOffset * 3600)
        return formatter.string(from: offsetDate)
    }

    private func formatTimeDifference() -> String? {
        let date = currentDate.addingTimeInterval(timeOffset * 3600)
        let seconds = entry.offsetDifference(at: date, relativeTo: effectiveLocalTimeZone)
        if seconds == 0 { return nil }
        let hours = Double(seconds) / 3600.0
        let formatted = String(format: "%.1f", abs(hours)).replacingOccurrences(of: ".0", with: "")
        if hours > 0 {
            return "+\(formatted)h"
        } else {
            return "-\(formatted)h"
        }
    }

    /// 若跨日（如由于时差或滑块偏移进入前一天或次日），准确对比公历日期显示标签
    private func relativeDayDifference() -> String? {
        guard let tz = TimeZone(identifier: entry.timezoneIdentifier) else { return nil }
        let targetDate = currentDate.addingTimeInterval(timeOffset * 3600)

        var targetCal = Calendar(identifier: .gregorian)
        targetCal.timeZone = tz

        var localCal = Calendar(identifier: .gregorian)
        localCal.timeZone = effectiveLocalTimeZone

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0)!

        let realNow = Date()
        let localYMD = localCal.dateComponents([.year, .month, .day], from: realNow)
        let friendYMD = targetCal.dateComponents([.year, .month, .day], from: targetDate)

        guard let localDateInUTC = utcCal.date(from: localYMD),
              let friendDateInUTC = utcCal.date(from: friendYMD) else { return nil }

        let dayDiff = utcCal.dateComponents([.day], from: localDateInUTC, to: friendDateInUTC).day ?? 0

        if dayDiff == 0 {
            return timeOffset != 0 ? "今天" : nil
        } else if dayDiff == 1 {
            return "明天"
        } else if dayDiff == -1 {
            return "昨天"
        } else if dayDiff == 2 {
            return "后天"
        } else if dayDiff == -2 {
            return "前天"
        } else if dayDiff > 2 || dayDiff < -2 {
            let formatter = DateFormatter()
            formatter.timeZone = tz
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日 EEE"
            return formatter.string(from: targetDate)
        }
        return nil
    }
}

// MARK: - LocalEntryRow (我的时间)
struct LocalEntryRow: View {
    var currentDate: Date = Date()
    @Binding var timeOffset: Double
    var isAnchor: Bool = false
    var showSlider: Bool = false
    var onTap: () -> Void = {}
    var onRightClick: () -> Void = {}
    var onCloseSlider: () -> Void = {}

    @State private var isHovered: Bool = false
    @State private var cachedAvatarImage: NSImage? = nil
    @Environment(\.colorScheme) private var scheme
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userAvatarPath") private var userAvatarPath: String = ""
    @AppStorage("use24HourFormat") private var use24HourFormat: Bool = false
    @AppStorage("userTimezoneIdentifier") private var userTimezoneIdentifier: String = ""
    @AppStorage("userCustomCity") private var userCustomCity: String = ""

    private var effectiveLocalTimeZone: TimeZone {
        if !userTimezoneIdentifier.isEmpty, let tz = TimeZone(identifier: userTimezoneIdentifier) {
            return tz
        }
        return TimeZone.current
    }

    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "我的时间" : trimmed
    }

    private var subtitle: String {
        let tz = effectiveLocalTimeZone
        let name = tz.localizedName(for: .generic, locale: Locale(identifier: "zh_CN"))
            ?? tz.localizedName(for: .standard, locale: Locale(identifier: "zh_CN"))
            ?? tz.abbreviation()
            ?? tz.identifier
        let cityName = userCustomCity.trimmingCharacters(in: .whitespacesAndNewlines)
        if cityName.isEmpty {
            return name
        } else {
            let shortCity = cityName.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? cityName
            return "\(shortCity) · \(name)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 基本信息栏（点击直接进入时间穿梭，右键直接进入编辑）
            HStack(spacing: 10) {
                localAvatar
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(formattedLocalTime())
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    if let dayDiff = relativeDayDifference() {
                        Text(dayDiff)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule()
                                    .fill(scheme == .dark ? Color.accentColor : Color.accentColor.opacity(0.15))
                            )
                            .foregroundColor(scheme == .dark ? .white : .accentColor)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // 当事人那一条的时间穿梭进度条
            if showSlider {
                InlineTimeSlider(
                    timeOffset: $timeOffset,
                    timeZoneIdentifier: effectiveLocalTimeZone.identifier,
                    anchorName: displayName,
                    city: userCustomCity.isEmpty ? "本地" : userCustomCity,
                    currentDate: currentDate,
                    onClose: onCloseSlider
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, showSlider ? 8 : 7)
        .background(
            RoundedRectangle(cornerRadius: TimefolkTheme.Radius.large, style: .continuous)
                .fill(
                    showSlider
                        ? (scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        : (isHovered
                            ? TimefolkTheme.Colors.cardHoverBackground(colorScheme: scheme)
                            : (isAnchor && timeOffset != 0 ? Color.accentColor.opacity(0.04) : Color.clear))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: TimefolkTheme.Radius.large, style: .continuous)
                .strokeBorder(
                    showSlider
                        ? Color.accentColor.opacity(0.38)
                        : (isAnchor && timeOffset != 0
                            ? Color.accentColor.opacity(0.35)
                            : (isHovered ? TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme) : Color.clear)),
                    lineWidth: 0.5
                )
        )
        .contentShape(Rectangle())
        .onRightClick {
            onRightClick()
        }
        .onHover { hovered in
            withAnimation(TimefolkTheme.Animation.quick) {
                self.isHovered = hovered
            }
        }
        .onAppear {
            loadAvatar()
        }
        .onChange(of: userAvatarPath) { _ in
            loadAvatar()
        }
    }

    private func loadAvatar() {
        if !userAvatarPath.isEmpty {
            cachedAvatarImage = PhotoStorage.load(from: userAvatarPath)
        } else {
            cachedAvatarImage = nil
        }
    }

    private var localAvatar: some View {
        ZStack(alignment: .bottomTrailing) {
            if let customImg = cachedAvatarImage {
                Image(nsImage: customImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                    )
            } else {
                Circle()
                    .fill(scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            }

            timePeriodBadge
                .offset(x: 3, y: 3)
        }
    }

    private var timePeriodBadge: some View {
        let date = currentDate.addingTimeInterval(timeOffset * 3600)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = effectiveLocalTimeZone
        let hour = cal.component(.hour, from: date)
        let periodName: String
        switch hour {
        case 5 ..< 8: periodName = "earlyMorning"
        case 8 ..< 12: periodName = "lateMorning"
        case 12 ..< 15: periodName = "earlyAfternoon"
        case 15 ..< 17: periodName = "lateAfternoon"
        case 17 ..< 19: periodName = "earlyEvening"
        case 19 ..< 22: periodName = "evening"
        default: periodName = "night"
        }

        return ZStack {
            Circle()
                .fill(scheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color.white)
                .frame(width: 17, height: 17)
                .shadow(color: Color.black.opacity(0.2), radius: 1.5, x: 0, y: 1)

            Image(periodName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
        }
        .overlay(
            Circle()
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func formattedLocalTime() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = effectiveLocalTimeZone

        if use24HourFormat {
            formatter.dateFormat = "HH:mm"
        } else {
            let locale = Locale.current
            let template = "j:mm"
            if let formatString = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale) {
                formatter.dateFormat = formatString
            } else {
                formatter.timeStyle = .short
            }
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = effectiveLocalTimeZone
        let cleanBaseDate = timeOffset != 0 ? (cal.date(bySetting: .second, value: 0, of: currentDate) ?? currentDate) : currentDate
        let offsetDate = cleanBaseDate.addingTimeInterval(timeOffset * 3600)
        return formatter.string(from: offsetDate)
    }

    private func relativeDayDifference() -> String? {
        let targetDate = currentDate.addingTimeInterval(timeOffset * 3600)
        var localCal = Calendar(identifier: .gregorian)
        localCal.timeZone = effectiveLocalTimeZone

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0)!

        let realNow = Date()
        let localYMD = localCal.dateComponents([.year, .month, .day], from: realNow)
        let targetYMD = localCal.dateComponents([.year, .month, .day], from: targetDate)

        guard let localDateInUTC = utcCal.date(from: localYMD),
              let targetDateInUTC = utcCal.date(from: targetYMD) else { return nil }

        let dayDiff = utcCal.dateComponents([.day], from: localDateInUTC, to: targetDateInUTC).day ?? 0

        if dayDiff == 0 {
            return timeOffset != 0 ? "今天" : nil
        } else if dayDiff == 1 {
            return "明天"
        } else if dayDiff == -1 {
            return "昨天"
        } else if dayDiff == 2 {
            return "后天"
        } else if dayDiff == -2 {
            return "前天"
        } else if dayDiff > 2 || dayDiff < -2 {
            let formatter = DateFormatter()
            formatter.timeZone = effectiveLocalTimeZone
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日 EEE"
            return formatter.string(from: targetDate)
        }
        return nil
    }
}

// MARK: - NativeDatePickerView
final class CleanNativeDatePicker: NSDatePicker {
    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
    override func drawFocusRingMask() {}
    override var focusRingMaskBounds: NSRect { .zero }
}

struct NativeDatePickerView: NSViewRepresentable {
    @Binding var selectedDate: Date
    var timeZone: TimeZone? = nil
    var onChange: (Date) -> Void = { _ in }

    func makeNSView(context: Context) -> CleanNativeDatePicker {
        let picker = CleanNativeDatePicker()
        picker.datePickerStyle = .clockAndCalendar
        picker.datePickerElements = .yearMonthDay
        picker.focusRingType = .none
        picker.isBezeled = false
        picker.isBordered = false
        picker.drawsBackground = false
        if let cell = picker.cell as? NSDatePickerCell {
            cell.focusRingType = .none
        }
        if let timeZone = timeZone {
            picker.timeZone = timeZone
        }
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.dateChanged(_:))
        return picker
    }

    func updateNSView(_ nsView: CleanNativeDatePicker, context: Context) {
        if let timeZone = timeZone, nsView.timeZone != timeZone {
            nsView.timeZone = timeZone
        }
        if abs(nsView.dateValue.timeIntervalSince(selectedDate)) > 1.0 {
            nsView.dateValue = selectedDate
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: NativeDatePickerView

        init(_ parent: NativeDatePickerView) {
            self.parent = parent
        }

        @objc func dateChanged(_ sender: NSDatePicker) {
            parent.selectedDate = sender.dateValue
            parent.onChange(sender.dateValue)
        }
    }
}

// MARK: - InlineTimeSlider (嵌入在当事人那一条卡片内的时间穿梭进度条)
struct InlineTimeSlider: View {
    @Binding var timeOffset: Double
    let timeZoneIdentifier: String
    var anchorName: String = ""
    var city: String = ""
    var currentDate: Date = Date()
    var onClose: () -> Void

    @State private var sliderValue: Double = 0.0
    @State private var previousValue: Double = 0.0
    @State private var eventAddedNotice: Bool = false
    @State private var showingDatePicker: Bool = false
    @State private var selectedCalendarDate: Date = Date()
    @State private var isSpecificDateMode: Bool = false
    @State private var specificDateDayStart: Date? = nil
    @State private var specificDateHour: Double = 12.0
    @Environment(\.colorScheme) private var scheme

    private var offsetText: String {
        if isSpecificDateMode, let dayStart = specificDateDayStart {
            var cal = Calendar(identifier: .gregorian)
            if let tz = TimeZone(identifier: timeZoneIdentifier) { cal.timeZone = tz }
            let targetDate = dayStart.addingTimeInterval(specificDateHour * 3600)
            let formatter = DateFormatter()
            formatter.timeZone = cal.timeZone
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日 EEE"
            return formatter.string(from: targetDate)
        }

        if timeOffset == 0 {
            return "此刻"
        }

        let absOffset = abs(timeOffset)
        let sign = timeOffset > 0 ? "+" : "-"
        let days = Int(absOffset / 24)
        let remainingHours = absOffset.truncatingRemainder(dividingBy: 24)
        let formattedHours = String(format: "%.1f", remainingHours).replacingOccurrences(of: ".0", with: "")

        if days == 0 {
            let formattedTotal = String(format: "%.1f", absOffset).replacingOccurrences(of: ".0", with: "")
            return "\(sign)\(formattedTotal) 小时"
        } else if remainingHours == 0 {
            return "\(sign)\(days) 天"
        } else {
            return "\(sign)\(days)天 \(formattedHours)小时"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Divider()
                .opacity(0.4)
                .padding(.top, 4)
                .padding(.bottom, 2)

            // 顶部信息：偏移状态/日期（点击选日历） + 添加到日历 + 回到此刻 + 收起按钮
            HStack(alignment: .center, spacing: 6) {
                // 可交互的日期/偏移量提示胶囊
                Button {
                    var cal = Calendar(identifier: .gregorian)
                    if let tz = TimeZone(identifier: timeZoneIdentifier) { cal.timeZone = tz }
                    let currentTarget = currentDate.addingTimeInterval(timeOffset * 3600)
                    selectedCalendarDate = currentTarget
                    showingDatePicker.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isSpecificDateMode ? "calendar" : "clock.arrow.circlepath")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(width: 14, height: 14)
                            .popover(isPresented: $showingDatePicker) {
                                NativeDatePickerView(
                                    selectedDate: $selectedCalendarDate,
                                    timeZone: TimeZone(identifier: timeZoneIdentifier)
                                ) { newDate in
                                    selectDateFromCalendar(newDate)
                                }
                                .frame(width: 140, height: 148)
                                .scaleEffect(1.28, anchor: .center)
                                .frame(width: 180, height: 190)
                                .padding(10)
                            }

                        Text(offsetText)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .lineLimit(1)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                            .opacity(0.6)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill((timeOffset == 0 && !isSpecificDateMode)
                                ? (scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.05))
                                : (scheme == .dark ? Color.accentColor : Color.accentColor.opacity(0.18)))
                    )
                    .foregroundColor((timeOffset == 0 && !isSpecificDateMode) ? .secondary : (scheme == .dark ? .white : .accentColor))
                    .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
                .help("选择具体日期查看作息")

                Spacer()

                // 添加日历事件按钮（低调精致按钮风格）
                Button {
                    var cal = Calendar(identifier: .gregorian)
                    if let tz = TimeZone(identifier: timeZoneIdentifier) { cal.timeZone = tz }
                    let cleanCurrentDate = timeOffset != 0 ? (cal.date(bySetting: .second, value: 0, of: currentDate) ?? currentDate) : currentDate
                    let rawEventDate = cleanCurrentDate.addingTimeInterval(timeOffset * 3600)
                    let eventDate = cal.date(bySetting: .second, value: 0, of: rawEventDate) ?? rawEventDate

                    let isMe = anchorName == "我的时间" || anchorName.hasSuffix("(我)")
                    let eventTitle = isMe ? "Timefolk 规划日程" : "与 \(anchorName) 的日程"
                    CalendarEventHelper.createAndOpenEvent(
                        title: eventTitle,
                        startDate: eventDate,
                        durationMinutes: 30,
                        location: city,
                        note: "由 Timefolk 时区穿梭创建 (基准时区: \(timeZoneIdentifier))"
                    )
                    performHapticFeedback()
                    withAnimation(TimefolkTheme.Animation.quick) {
                        eventAddedNotice = true
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            withAnimation(TimefolkTheme.Animation.quick) {
                                eventAddedNotice = false
                            }
                        }
                    }
                } label: {
                    Image(systemName: eventAddedNotice ? "checkmark" : "calendar.badge.plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(eventAddedNotice ? .white : .primary)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(eventAddedNotice
                                    ? Color.green
                                    : (scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)))
                        )
                }
                .buttonStyle(.plain)
                .help(eventAddedNotice ? "已在日历打开" : "在此时刻向日历添加事件")

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("收起")
            }

            // 穿梭滑块
            if isSpecificDateMode {
                Slider(value: $sliderValue, in: 0.0 ... 24.0, step: 0.5)
                    .tint(Color.accentColor)
                    .onChange(of: sliderValue) { newValue in
                        updateSpecificDateOffset(for: newValue)
                        if Int(newValue) != Int(previousValue) {
                            performHapticFeedback()
                        }
                        previousValue = newValue
                    }

                // 24 小时快捷跳转标记点
                HStack {
                    quickHourButton(title: "00:00", targetHour: 0.0)
                    Spacer()
                    quickHourButton(title: "09:00", targetHour: 9.0)
                    Spacer()
                    quickHourButton(title: "12:00", targetHour: 12.0)
                    Spacer()
                    quickHourButton(title: "18:00", targetHour: 18.0)
                    Spacer()
                    quickHourButton(title: "22:00", targetHour: 22.0)
                }
                .padding(.horizontal, 2)
            } else {
                Slider(value: $sliderValue, in: -72.0 ... 72.0, step: 0.5)
                    .tint(Color.accentColor)
                    .onChange(of: sliderValue) { newValue in
                        updateTimeOffset(for: newValue)
                        if Int(newValue) != Int(previousValue) {
                            performHapticFeedback()
                        }
                        previousValue = newValue
                    }

                // 快捷跳转标记点：前后各3天
                HStack {
                    quickJumpButton(title: "-3天", targetSliderValue: -72.0)
                    Spacer()
                    quickJumpButton(title: "-1天", targetSliderValue: -24.0)
                    Spacer()
                    quickJumpButton(title: "此刻", targetSliderValue: 0.0)
                    Spacer()
                    quickJumpButton(title: "+1天", targetSliderValue: 24.0)
                    Spacer()
                    quickJumpButton(title: "+3天", targetSliderValue: 72.0)
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.top, 2)
        .padding(.bottom, 2)
        .onAppear {
            syncSliderFromOffset()
        }
        .onChange(of: timeOffset) { newOffset in
            if newOffset == 0.0 {
                isSpecificDateMode = false
                specificDateDayStart = nil
                syncSliderFromOffset()
            }
        }
    }

    private func selectDateFromCalendar(_ date: Date) {
        var cal = Calendar(identifier: .gregorian)
        if let tz = TimeZone(identifier: timeZoneIdentifier) { cal.timeZone = tz }

        let dayStart = cal.startOfDay(for: date)
        specificDateDayStart = dayStart
        isSpecificDateMode = true

        let currentHour = Double(cal.component(.hour, from: currentDate))
        let currentMin = Double(cal.component(.minute, from: currentDate))
        let initialHour = currentHour + (currentMin >= 30 ? 0.5 : 0.0)
        specificDateHour = initialHour

        let targetDate = dayStart.addingTimeInterval(initialHour * 3600)
        timeOffset = targetDate.timeIntervalSince(currentDate) / 3600.0
        sliderValue = initialHour
        previousValue = initialHour
        performHapticFeedback()
    }

    private func updateSpecificDateOffset(for newHour: Double) {
        guard let dayStart = specificDateDayStart else { return }
        specificDateHour = newHour
        let targetDate = dayStart.addingTimeInterval(newHour * 3600)
        timeOffset = targetDate.timeIntervalSince(currentDate) / 3600.0
    }

    private func syncSliderFromOffset() {
        if isSpecificDateMode {
            sliderValue = specificDateHour
            previousValue = specificDateHour
        } else if timeOffset == 0.0 {
            sliderValue = 0.0
            previousValue = 0.0
        } else {
            sliderValue = (timeOffset * 2).rounded() / 2
            previousValue = sliderValue
        }
    }

    private func updateTimeOffset(for newSliderValue: Double) {
        if newSliderValue == 0.0 {
            timeOffset = 0.0
        } else {
            var cal = Calendar(identifier: .gregorian)
            if let tz = TimeZone(identifier: timeZoneIdentifier) {
                cal.timeZone = tz
            } else {
                cal.timeZone = TimeZone.current
            }
            let now = Date()
            let cleanNow = cal.date(bySetting: .second, value: 0, of: now) ?? now
            let startOfHour = cal.dateInterval(of: .hour, for: cleanNow)?.start ?? cleanNow
            let target = cal.date(byAdding: .minute, value: Int(newSliderValue * 60), to: startOfHour) ?? cleanNow
            timeOffset = target.timeIntervalSince(cleanNow) / 3600.0
        }
    }

    private func performHapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }

    @ViewBuilder
    private func quickJumpButton(title: String, targetSliderValue: Double) -> some View {
        let isSelected = abs(sliderValue - targetSliderValue) < 0.25
        Button {
            withAnimation(TimefolkTheme.Animation.quick) {
                sliderValue = targetSliderValue
                updateTimeOffset(for: targetSliderValue)
                performHapticFeedback()
            }
        } label: {
            Text(title)
                .font(.system(size: 10.5, weight: isSelected ? .bold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func quickHourButton(title: String, targetHour: Double) -> some View {
        let isSelected = abs(sliderValue - targetHour) < 0.25
        Button {
            withAnimation(TimefolkTheme.Animation.quick) {
                sliderValue = targetHour
                updateSpecificDateOffset(for: targetHour)
                performHapticFeedback()
            }
        } label: {
            Text(title)
                .font(.system(size: 10.5, weight: isSelected ? .bold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
