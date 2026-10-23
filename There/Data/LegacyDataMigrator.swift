import Foundation
import GRDB

/// Handles migration of user data when transitioning from legacy bundle identifier `pm.there.There`
/// to `com.timefolk.Timefolk` across macOS sandboxed or unsandboxed environments.
enum LegacyDataMigrator {
    static func migrateIfNeeded(to targetAppSupportURL: URL, userDefaults: UserDefaults = .standard) {
        let fileManager = FileManager.default
        let targetDBURL = targetAppSupportURL
            .appendingPathComponent("Database", isDirectory: true)
            .appendingPathComponent("db.sqlite")

        // If target database already exists, no migration needed
        if fileManager.fileExists(atPath: targetDBURL.path) {
            userDefaults.set(true, forKey: "hasSeededDefaultEntries")
            return
        }

        let homeDir = fileManager.homeDirectoryForCurrentUser

        // Possible legacy database locations
        let legacyCandidates: [URL] = [
            // Sandboxed container of pm.there.There
            homeDir.appendingPathComponent("Library/Containers/pm.there.There/Data/Library/Application Support/Database/db.sqlite"),
            // Legacy unsandboxed Application Support/There
            homeDir.appendingPathComponent("Library/Application Support/There/Database/db.sqlite"),
            // Legacy unsandboxed Application Support/Database
            homeDir.appendingPathComponent("Library/Application Support/Database/db.sqlite"),
            // App Group container if any
            homeDir.appendingPathComponent("Library/Group Containers/group.pm.there.There/Database/db.sqlite")
        ]

        guard let sourceDBURL = legacyCandidates.first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            return
        }

        NSLog("[Migration] Found legacy There database at \(sourceDBURL.path). Starting migration to \(targetDBURL.path)...")

        let sourceDBDir = sourceDBURL.deletingLastPathComponent()
        let targetDBDir = targetDBURL.deletingLastPathComponent()
        let sourceAppSupport = sourceDBDir.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: targetDBDir, withIntermediateDirectories: true)

            // Copy sqlite database and auxiliary journal files (-wal, -shm)
            let dbFiles = ["db.sqlite", "db.sqlite-wal", "db.sqlite-shm"]
            for file in dbFiles {
                let src = sourceDBDir.appendingPathComponent(file)
                let dst = targetDBDir.appendingPathComponent(file)
                if fileManager.fileExists(atPath: src.path) && !fileManager.fileExists(atPath: dst.path) {
                    try? fileManager.copyItem(at: src, to: dst)
                }
            }

            // Copy Photos directory
            let sourcePhotosDir = sourceAppSupport.appendingPathComponent("Photos", isDirectory: true)
            let targetPhotosDir = targetAppSupportURL.appendingPathComponent("Photos", isDirectory: true)
            if fileManager.fileExists(atPath: sourcePhotosDir.path) {
                try fileManager.createDirectory(at: targetPhotosDir, withIntermediateDirectories: true)
                if let contents = try? fileManager.contentsOfDirectory(atPath: sourcePhotosDir.path) {
                    for item in contents {
                        let srcItem = sourcePhotosDir.appendingPathComponent(item)
                        let dstItem = targetPhotosDir.appendingPathComponent(item)
                        if !fileManager.fileExists(atPath: dstItem.path) {
                            try? fileManager.copyItem(at: srcItem, to: dstItem)
                        }
                    }
                }
            }

            // Migrate Preferences from pm.there.There
            migratePreferences(homeDir: homeDir, userDefaults: userDefaults)

            // Mark default entries as already seeded so default Tibo isn't injected into migrated DB
            userDefaults.set(true, forKey: "hasSeededDefaultEntries")

            NSLog("[Migration] Successfully completed migration from There to Timefolk.")
        } catch {
            NSLog("[Migration] Error during migration: \(error)")
        }
    }

    private static func migratePreferences(homeDir: URL, userDefaults: UserDefaults) {
        let fileManager = FileManager.default
        let legacyPlistCandidates = [
            homeDir.appendingPathComponent("Library/Containers/pm.there.There/Data/Library/Preferences/pm.there.There.plist"),
            homeDir.appendingPathComponent("Library/Preferences/pm.there.There.plist")
        ]

        var legacyDict: [String: Any]? = nil

        // Try reading via UserDefaults suite first
        if let suite = UserDefaults(suiteName: "pm.there.There") {
            let dict = suite.dictionaryRepresentation()
            if !dict.isEmpty {
                legacyDict = dict
            }
        }

        // Fallback to direct plist file reading if accessible
        if legacyDict == nil {
            for plistURL in legacyPlistCandidates {
                if fileManager.fileExists(atPath: plistURL.path),
                   let data = try? Data(contentsOf: plistURL),
                   let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                    legacyDict = plist
                    break
                }
            }
        }

        guard let dict = legacyDict else { return }

        let keysToMigrate = [
            "userName",
            "userAvatarPath",
            "use24HourFormat",
            "sortOrder",
            "firstTime",
            "userTimezoneIdentifier",
            "userCustomCity"
        ]

        for key in keysToMigrate {
            if let value = dict[key], userDefaults.object(forKey: key) == nil {
                userDefaults.set(value, forKey: key)
            }
        }
    }
}
