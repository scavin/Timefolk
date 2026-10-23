import Foundation
import SwiftUI

class Utils {
    public static var shared = Utils()
    func selectPhoto(completion: @escaping (NSImage?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.jpeg, .png, .heic]
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "选定"
        openPanel.level = .floating
        NSApp.activate(ignoringOtherApps: true)
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url, let image = NSImage(contentsOf: url) {
                completion(image.resizedForAvatar())
            } else {
                completion(nil)
            }
        }
    }
}

enum SocialAvatarFetcher {
    static func fetch(platform: String, username: String) async throws -> NSImage? {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        guard !clean.isEmpty else { return nil }
        guard let escaped = clean.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/?#"))) else { return nil }
        let normalized = platform.lowercased() == "twitter" ? "x" : platform.lowercased()
        let urlString = "https://unavatar.io/\(normalized)/\(escaped)"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            return nil
        }
        guard let rawImage = NSImage(data: data) else { return nil }
        return rawImage.resizedForAvatar(maxPixelSize: 512)
    }
}
