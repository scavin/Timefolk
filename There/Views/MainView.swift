import AppKit
import GRDB
import SwiftUI

struct MainView: View {
    @StateObject private var fetcher = Fetcher()
    @AppStorage("sortOrder") private var sortOrder: SortOrder = .timeAscending
    @State private var operationError: String?
    @Environment(\.database) var database: AppDatabase
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: Router
    @State private var isAtBottom: Bool = false
    @State private var showSlider: Bool = false
    @State private var anchorEntryId: Int64? = nil
    @State var timeOffset: Double = 0

    var body: some View {
        VStack(alignment: sortedEntries.isEmpty ? .center : .leading, spacing: 0) {
            if sortedEntries.isEmpty {
                Spacer()
                EmptyTimezoneView()
                Spacer()
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 2) {
                        TimelineView(.periodic(from: Calendar.current.dateInterval(of: .minute, for: .now)?.start ?? .now, by: 60)) { context in
                            // 本地用户时间卡片（固定在顶部）
                            LocalEntryRow(
                                currentDate: context.date,
                                timeOffset: $timeOffset,
                                isAnchor: anchorEntryId == nil,
                                showSlider: showSlider && anchorEntryId == nil,
                                onTap: {
                                    withAnimation(TimefolkTheme.Animation.smooth) {
                                        if showSlider && anchorEntryId == nil {
                                            showSlider = false
                                        } else {
                                            anchorEntryId = nil
                                            showSlider = true
                                        }
                                    }
                                },
                                onRightClick: {
                                    router.setActiveRoute(to: .editProfile)
                                },
                                onCloseSlider: {
                                    withAnimation(TimefolkTheme.Animation.quick) {
                                        showSlider = false
                                    }
                                }
                            )
                            .id("local-user-entry")

                            // 好友列表
                            ForEach(sortedEntries) { entry in
                                EntryRow(
                                    entry: entry,
                                    currentDate: context.date,
                                    timeOffset: $timeOffset,
                                    isAnchor: anchorEntryId == entry.id,
                                    showSlider: showSlider && anchorEntryId == entry.id,
                                    onTap: {
                                        withAnimation(TimefolkTheme.Animation.smooth) {
                                            if showSlider && anchorEntryId == entry.id {
                                                showSlider = false
                                            } else {
                                                anchorEntryId = entry.id
                                                showSlider = true
                                            }
                                        }
                                    },
                                    onRightClick: {
                                        router.setActiveRoute(to: .editTimeZone(entryId: entry.id))
                                    },
                                    onCloseSlider: {
                                        withAnimation(TimefolkTheme.Animation.quick) {
                                            showSlider = false
                                        }
                                    }
                                )
                                .id(entry.id)
                            }
                            .animation(.easeInOut(duration: 0.1), value: sortedEntries.count)
                        }

                        Color.clear
                            .frame(height: 2)
                            .onAppear {
                                isAtBottom = false
                            }
                            .onDisappear {
                                isAtBottom = true
                            }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
            }

            BottomBarView(
                isAtBottom: $isAtBottom,
                sortOrder: $sortOrder,
                timeOffset: $timeOffset,
                onResetTime: {
                    withAnimation(TimefolkTheme.Animation.quick) {
                        timeOffset = 0.0
                    }
                }
            )
        }
        .frame(maxHeight: .infinity)
        .onChange(of: appState.menuBarViewIsPresented) { isPresented in
            if !isPresented {
                // 窗口关闭时重置穿梭状态与滑块
                showSlider = false
                timeOffset = 0.0
            }
        }
        .alert("删除失败", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("好") { operationError = nil }
        } message: {
            Text(operationError ?? "")
        }
    }

    @AppStorage("userTimezoneIdentifier") private var userTimezoneIdentifier: String = ""

    private var effectiveLocalTimeZone: TimeZone {
        if !userTimezoneIdentifier.isEmpty, let tz = TimeZone(identifier: userTimezoneIdentifier) {
            return tz
        }
        return TimeZone.current
    }

    private var sortedEntries: [Entry] {
        let now = Date().addingTimeInterval(timeOffset * 3600)
        let tz = effectiveLocalTimeZone
        return fetcher.entries.sorted {
            let left = $0.offsetDifference(at: now, relativeTo: tz)
            let right = $1.offsetDifference(at: now, relativeTo: tz)
            if left == right { return $0.id < $1.id }
            return sortOrder == .timeAscending ? left < right : left > right
        }
    }

    private func deleteEntry(_ entry: Entry) {
        Task {
            do {
                try await database.dbWriter.write { db in
                    let fetchedEntry = try Entry.fetchOne(db, id: entry.id)
                    try fetchedEntry?.delete(db)
                }
                PhotoStorage().remove(entry.photoData)
            } catch {
                operationError = error.localizedDescription
            }
        }
    }
}

#Preview {
    MainView()
        .frame(width: 400, height: 400)
}

extension Date {
    var hour: Double {
        Double(Calendar.current.component(.hour, from: self)) + (Calendar.current.component(.minute, from: self) >= 30 ? 0.5 : 0.0)
    }
}
