// EditProfileView.swift

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct EditProfileView: View {
    @EnvironmentObject var router: Router
    @Environment(\.colorScheme) private var scheme
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userAvatarPath") private var userAvatarPath: String = ""
    @AppStorage("userTimezoneIdentifier") private var storedTimezoneId: String = ""
    @AppStorage("userCustomCity") private var storedCustomCity: String = ""

    enum AvatarSource: String, CaseIterable, Identifiable {
        case local = "本地"
        case telegram = "Telegram"
        case x = "X"

        var id: String { rawValue }
    }

    @State private var name: String = ""
    @State private var avatarImage: NSImage? = nil
    @State private var isHoveredOnAvatar: Bool = false
    @State private var isDropTargeted: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    // 时区与城市
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var isShowingCityPopover: Bool = false
    @State private var selectedTimeZone: TimeZone? = nil
    @State private var selectedCity: String = ""

    // 社交平台抓取
    @State private var activeSource: AvatarSource = .local
    @State private var socialHandle: String = ""
    @State private var isFetchingAvatar: Bool = false
    @State private var fetchMessage: String? = nil
    @State private var debounceTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 0) {
            Titlebar()

            ScrollView(.vertical) {
                VStack(spacing: 12) {
                    // 头像选取与展示区域
                    VStack(spacing: 8) {
                        avatarView
                            .frame(width: 64, height: 64)
                            .onTapGesture {
                                chooseAvatarImage()
                            }
                            .onDrop(of: [.fileURL, .image], isTargeted: $isDropTargeted, perform: handleDrop)

                        // 来源切换选择器：本地 / Telegram / X
                        Picker("", selection: $activeSource) {
                            ForEach(AvatarSource.allCases) { source in
                                Text(source.rawValue).tag(source)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(.horizontal, 24)
                        .onChange(of: activeSource) { _ in
                            socialHandle = ""
                            fetchMessage = nil
                        }

                        // 对应来源的操作区域
                        sourceInputSection
                            .padding(.horizontal, 24)

                        if avatarImage != nil {
                            Button("移除头像") {
                                withAnimation(TimefolkTheme.Animation.quick) {
                                    avatarImage = nil
                                    socialHandle = ""
                                    fetchMessage = nil
                                }
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                            .buttonStyle(.link)
                            .padding(.top, -2)
                        }
                    }
                    .padding(.top, 4)

                    // 称呼输入
                    Input(text: $name, placeholder: "称呼（如：阿杰、Alex）", icon: "person")
                        .padding(.horizontal, 24)

                    // 所在时区与城市
                    VStack(spacing: 0) {
                        Button {
                            isShowingCityPopover = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: selectedTimeZone == nil ? "location.fill" : "mappin.and.ellipse")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedTimeZone == nil ? .secondary : .accentColor)

                                if let tz = selectedTimeZone {
                                    let tzName = tz.localizedName(for: .generic, locale: Locale(identifier: "zh_CN"))
                                        ?? tz.localizedName(for: .standard, locale: Locale(identifier: "zh_CN"))
                                        ?? tz.abbreviation()
                                        ?? tz.identifier
                                    let cityText = selectedCity.isEmpty ? "" : "\(selectedCity) · "
                                    Text("\(cityText)\(tzName)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                } else {
                                    let sysTz = TimeZone.current
                                    let sysName = sysTz.localizedName(for: .generic, locale: Locale(identifier: "zh_CN"))
                                        ?? sysTz.localizedName(for: .standard, locale: Locale(identifier: "zh_CN"))
                                        ?? sysTz.abbreviation()
                                        ?? sysTz.identifier
                                    Text("跟随系统（\(sysName)）")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if selectedTimeZone != nil {
                                    Button {
                                        withAnimation(TimefolkTheme.Animation.quick) {
                                            selectedTimeZone = nil
                                            selectedCity = ""
                                        }
                                    } label: {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("恢复跟随系统时区")
                                }

                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .popover(isPresented: $isShowingCityPopover) {
                            CitySearchResults(
                                searchCompleter: searchCompleter,
                                isShowingPopover: $isShowingCityPopover,
                                selectedName: .constant(""),
                                selectedCity: $selectedCity,
                                selectedTimezone: $selectedTimeZone
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    // 操作按钮
                    HStack(spacing: 12) {
                        SecondaryButton(title: "取消") {
                            withAnimation(TimefolkTheme.Animation.quick) {
                                router.cleanActiveRoute()
                            }
                        }

                        PrimaryButton(title: isSaving ? "保存中…" : "保存资料", action: saveProfile)
                            .disabled(isSaving)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 2)
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            name = userName
            if !storedTimezoneId.isEmpty, let tz = TimeZone(identifier: storedTimezoneId) {
                selectedTimeZone = tz
                selectedCity = storedCustomCity
            } else {
                selectedTimeZone = nil
                selectedCity = ""
            }
            if !userAvatarPath.isEmpty {
                avatarImage = PhotoStorage.load(from: userAvatarPath)
            }
        }
        .onDisappear {
            debounceTask?.cancel()
        }
    }

    @ViewBuilder
    private var sourceInputSection: some View {
        switch activeSource {
        case .local:
            Button {
                chooseAvatarImage()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 11))
                    Text("选取本地图片…")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        case .telegram:
            socialInputField(
                placeholder: "@username（如 durov）",
                icon: "paperplane"
            )
        case .x:
            socialInputField(
                placeholder: "@username（如 elonmusk）",
                icon: "at"
            )
        }
    }

    private func socialInputField(placeholder: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Input(
                    text: $socialHandle,
                    placeholder: placeholder,
                    icon: icon
                )
                .onChange(of: socialHandle) { value in
                    handleSocialFetch(username: value)
                }

                if isFetchingAvatar {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 18, height: 18)
                }
            }

            if let msg = fetchMessage {
                Text(msg)
                    .font(.system(size: 10))
                    .foregroundColor(msg.contains("成功") ? .accentColor : .secondary)
                    .padding(.horizontal, 2)
            }
        }
    }

    private func handleSocialFetch(username: String) {
        debounceTask?.cancel()
        fetchMessage = nil

        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        guard !clean.isEmpty else {
            isFetchingAvatar = false
            return
        }

        let platform = activeSource == .telegram ? "telegram" : "x"
        isFetchingAvatar = true

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }

            do {
                if let fetched = try await SocialAvatarFetcher.fetch(platform: platform, username: clean) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(TimefolkTheme.Animation.quick) {
                            self.avatarImage = fetched
                            self.isFetchingAvatar = false
                            self.fetchMessage = "已成功获取头像"
                        }
                    }
                } else {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.isFetchingAvatar = false
                        self.fetchMessage = "未找到该用户的公开头像"
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isFetchingAvatar = false
                    self.fetchMessage = "获取超时，请检查网络"
                }
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            if let img = avatarImage {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                    )
            } else {
                Circle()
                    .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.accentColor.opacity(0.85))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            }

            // 悬停提示遮罩
            Circle()
                .fill(Color.black.opacity(isHoveredOnAvatar ? 0.35 : 0.0))
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .opacity(isHoveredOnAvatar ? 1.0 : 0.0)
                )
                .animation(TimefolkTheme.Animation.quick, value: isHoveredOnAvatar)
        }
        .contentShape(Circle())
        .onHover { isHoveredOnAvatar = $0 }
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }

    private func chooseAvatarImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.title = "选择个人头像"
        panel.prompt = "选定"
        panel.level = .floating

        // 关键：激活应用，确保文件对话框浮于菜单栏窗口上方，且非阻塞式运行
        NSApp.activate(ignoringOtherApps: true)

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            self.loadAndSetAvatar(from: url)
        }
    }

    private func loadAndSetAvatar(from url: URL) {
        Task.detached(priority: .userInitiated) {
            guard let image = NSImage(contentsOf: url) else { return }
            let resized = image.resizedForAvatar(maxPixelSize: 512)
            await MainActor.run {
                withAnimation(TimefolkTheme.Animation.quick) {
                    self.avatarImage = resized
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // 1. 支持 Finder 文件拖拽
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                self.loadAndSetAvatar(from: url)
            }
            return true
        }

        // 2. 支持图片数据拖拽 (如浏览器图片/照片App)
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data, let image = NSImage(data: data) else { return }
                let resized = image.resizedForAvatar(maxPixelSize: 512)
                DispatchQueue.main.async {
                    withAnimation(TimefolkTheme.Animation.quick) {
                        self.avatarImage = resized
                    }
                }
            }
            return true
        }

        return false
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = trimmedName
        storedTimezoneId = selectedTimeZone?.identifier ?? ""
        storedCustomCity = selectedCity.trimmingCharacters(in: .whitespacesAndNewlines)

        isSaving = true
        let imageToSave = avatarImage
        let oldPath = userAvatarPath
        let photos = PhotoStorage()

        Task.detached(priority: .userInitiated) {
            var newPath: String? = nil
            var saveError: String? = nil

            if let img = imageToSave {
                do {
                    newPath = try photos.save(img)
                    if let newPath, !oldPath.isEmpty, oldPath != newPath {
                        photos.remove(oldPath)
                    }
                } catch {
                    saveError = "保存头像失败，请重试。"
                }
            } else {
                // 移除头像
                if !oldPath.isEmpty {
                    photos.remove(oldPath)
                }
                newPath = ""
            }

            await MainActor.run {
                self.isSaving = false
                if let saveError {
                    self.errorMessage = saveError
                } else {
                    if let newPath {
                        self.userAvatarPath = newPath
                    }
                    withAnimation(TimefolkTheme.Animation.quick) {
                        self.router.cleanActiveRoute()
                    }
                }
            }
        }
    }
}
