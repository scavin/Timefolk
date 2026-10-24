import AppKit
import MapKit
import SwiftUI

// MARK: - IconView

struct IconView: View {
    @Binding var image: NSImage?
    @Environment(\.colorScheme) private var scheme

    @State private var showPopover = false
    @State private var isDropTargeted = false
    @State private var showingXAccountInput = false
    @State private var showingTGAccountInput = false
    @State private var username = ""
    @State private var debounceTask: Task<Void, Never>?
    @State private var isHovered = false

    var body: some View {
        iconContent
            .frame(width: 64, height: 64)
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .animation(TimefolkTheme.Animation.quick, value: isHovered)
            .onHover { hovering in
                self.isHovered = hovering
            }
            .onTapGesture { showPopover = true }
            .popover(isPresented: $showPopover) { popoverContent }
            .onDrop(of: [.image], isTargeted: $isDropTargeted, perform: handleDrop)
    }

    private var iconContent: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
            } else {
                placeholderView
            }
        }
    }

    private var placeholderView: some View {
        Circle()
            .fill(scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            .overlay(
                Image(systemName: "camera.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        Color.primary.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
    }

    private var popoverContent: some View {
        VStack(spacing: 10) {
            importButtons

            if showingXAccountInput {
                SocialMediaInput(platform: "X", username: $username, image: $image, debounceTask: $debounceTask)
                    .onSubmit {
                        showPopover = false
                    }
            } else if showingTGAccountInput {
                SocialMediaInput(platform: "Telegram", username: $username, image: $image, debounceTask: $debounceTask)
                    .onSubmit {
                        showPopover = false
                    }
            }
        }
        .padding(14)
        .frame(width: 240)
    }

    private var importButtons: some View {
        HStack(spacing: 6) {
            Button("Telegram") {
                withAnimation(TimefolkTheme.Animation.quick) {
                    showingXAccountInput = false
                    showingTGAccountInput = true
                }
            }
            .buttonStyle(SecondaryButtonStyle())

            Button("X") {
                withAnimation(TimefolkTheme.Animation.quick) {
                    showingTGAccountInput = false
                    showingXAccountInput = true
                }
            }
            .buttonStyle(SecondaryButtonStyle())

            Button("本地照片") {
                Utils.shared.selectPhoto { selectedImage in
                    guard let selectedImage else { return }
                    DispatchQueue.main.async {
                        self.image = selectedImage
                        self.showPopover = false
                    }
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSImage.self) { object, _ in
            if let image = object as? NSImage {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
        return true
    }
}

// MARK: - CitySearchResultRow

struct CitySearchResultRow: View, Equatable {
    let result: TimeZoneSearchResult

    var body: some View {
        HStack(spacing: 8) {
            if result == .tibo, let tiboImage = NSImage(named: "tibo") {
                Image(nsImage: tiboImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            } else {
                Image(systemName: result.type == .city ? "mappin.circle.fill" : "globe")
                    .font(.system(size: 14))
                    .foregroundColor(result.type == .city ? .accentColor : .secondary)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(result.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                if !result.subtitle.isEmpty {
                    Text(result.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    static func == (lhs: CitySearchResultRow, rhs: CitySearchResultRow) -> Bool {
        lhs.result == rhs.result
    }
}

// MARK: - CitySearchResults

struct CitySearchResults: View {
    @ObservedObject var searchCompleter: SearchCompleter
    @Binding var isShowingPopover: Bool
    @Binding var selectedName: String
    @Binding var selectedCity: String
    @Binding var selectedTimezone: TimeZone?
    var image: Binding<NSImage?>? = nil
    @FocusState private var isFocused: Bool
    @State private var selectedIndex: Int = -1
    @State private var selectionTask: Task<Void, Never>?
    @State private var selectionError: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 8) {
            CustomTextField(text: $searchCompleter.queryFragment, placeholder: "搜索城市或时区…", onKeyDown: handleKeyEvent)
                .padding(.horizontal, 8)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                        .fill(
                            scheme == .dark
                                ? Color.white.opacity(0.06)
                                : Color.black.opacity(0.04)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TimefolkTheme.Radius.medium, style: .continuous)
                        .strokeBorder(
                            isFocused ? Color.accentColor : TimefolkTheme.Colors.hairlineBorder(colorScheme: scheme),
                            lineWidth: isFocused ? 1.5 : 0.5
                        )
                )
                .focused($isFocused)
                .padding(.horizontal, 10)
                .padding(.top, 10)

            if let selectionError {
                Text(selectionError)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
            }

            ScrollViewReader { proxy in
                List(searchCompleter.results.indices, id: \.self) { index in
                    let result = searchCompleter.results[index]

                    Button(action: {
                        self.selectCity(result)
                    }) {
                        CitySearchResultRow(result: result)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: TimefolkTheme.Radius.small, style: .continuous)
                            .fill(selectedIndex == index ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                    .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    .id(index)
                }
                .listStyle(.plain)
                .onChange(of: selectedIndex) { newValue in
                    if newValue >= 0 {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 300, height: 360)
        .onChange(of: searchCompleter.queryFragment) { _ in
            selectedIndex = -1
            selectionTask?.cancel()
            selectionError = nil
        }
        .onDisappear { selectionTask?.cancel() }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126: // Up arrow
            moveSelection(direction: .up)
            return true
        case 125: // Down arrow
            moveSelection(direction: .down)
            return true
        case 36: // Return key
            if selectedIndex >= 0 && selectedIndex < searchCompleter.results.count {
                selectCity(searchCompleter.results[selectedIndex])
                return true
            }
            return false
        default:
            return false
        }
    }

    private func moveSelection(direction: KeyboardNavigationDirection) {
        let count = searchCompleter.results.count
        guard count > 0 else { return }

        switch direction {
        case .up:
            selectedIndex = (selectedIndex - 1 + count) % count
        case .down:
            selectedIndex = (selectedIndex + 1) % count
        case .enter:
            break
        }
    }

    private func selectCity(_ result: TimeZoneSearchResult) {
        selectionError = nil
        selectionTask?.cancel()
        selectionTask = Task { @MainActor in
            let timezone = await result.getTimeZone()
            guard !Task.isCancelled else { return }
            guard let timezone else {
                selectionError = "Could not resolve this time zone. Please try another result."
                return
            }
            selectedCity = result.subtitle.isEmpty ? result.title : "\(result.title), \(result.subtitle)"
            selectedTimezone = timezone
            if result == .tibo {
                image?.wrappedValue = NSImage(named: "tibo")
            }
            isShowingPopover = false
        }
    }
}

// MARK: - CustomTextField

struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onKeyDown: (NSEvent) -> Bool

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.focusRingType = .none
        textField.drawsBackground = false
        textField.isBordered = false
        textField.textColor = .labelColor
        textField.font = .systemFont(ofSize: 13)
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                return parent.onKeyDown(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 126)!)
            } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
                return parent.onKeyDown(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 125)!)
            } else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                return parent.onKeyDown(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36)!)
            }
            return false
        }
    }
}

enum KeyboardNavigationDirection {
    case up, down, enter
}
