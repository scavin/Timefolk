import SwiftUI

struct IconSection: View {
    @Binding var image: NSImage?
    @Binding var showingXAccountInput: Bool
    @Binding var showingTGAccountInput: Bool

    @State private var xHovered = false
    @State private var tgHovered = false

    var body: some View {
        VStack {
            IconView(
                image: $image
            )
            .padding(.bottom, 6)
        }
    }
}

struct SocialMediaButton: View {
    let imageName: String
    @Binding var isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .frame(width: 18, height: 18)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.1 : 1)
        .shadow(color: isHovered ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 4)
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
    }
}

struct SocialMediaInput: View {
    let platform: String
    @Binding var username: String
    @Binding var image: NSImage?
    @Binding var debounceTask: Task<Void, Never>?

    var body: some View {
        Input(
            text: $username,
            placeholder: platform == "X" ? "@username" : "用户名",
            icon: "at"
        )
        .padding(.top, 2)
        .onChange(of: username) { value in
                debounceTask?.cancel()

                let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                guard !clean.isEmpty else {
                    image = nil
                    return
                }

                debounceTask = Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    guard !Task.isCancelled else { return }

                    do {
                        if let fetchedImage = try await SocialAvatarFetcher.fetch(platform: platform, username: clean) {
                            guard !Task.isCancelled else { return }
                            await MainActor.run {
                                withAnimation(TimefolkTheme.Animation.quick) {
                                    self.image = fetchedImage
                                }
                            }
                        }
                    } catch {
                        // 网络异常或未找到
                    }
                }
            }
            .onDisappear { debounceTask?.cancel() }
    }
}
