import Foundation
import GRDB

extension AppDatabase {
    /// The database for the application
    static let shared = makeShared()

    private static func makeShared() -> AppDatabase {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            CommandLine.arguments.contains("-ui-testing") {
            return empty()
        }
        do {
            // Apply recommendations from
            // <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections>
            //
            // Create the "Application Support/Database" directory if needed
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)

            // Support for tests: delete the database if requested
            if CommandLine.arguments.contains("-reset") {
                try? fileManager.removeItem(at: directoryURL)
            }

            // 升级与迁移：检测并迁移旧应用标识 pm.there.There 的旧沙盒/本地数据
            LegacyDataMigrator.migrateIfNeeded(to: appSupportURL)

            // Create the database folder if needed
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            // Open or create the database
            let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
            NSLog("Database stored at \(databaseURL.path)")
            let dbPool = try DatabasePool(
                path: databaseURL.path,
                // Use default AppDatabase configuration
                configuration: AppDatabase.makeConfiguration())

            // Create the AppDatabase
            let appDatabase = try AppDatabase(dbPool)

            // 首次安装启动时，若数据库为空，默认预置 Tibo 好友时钟
            seedDefaultEntriesIfNeeded(in: dbPool)

            return appDatabase
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            //
            // Typical reasons for an error here include:
            // * The parent directory cannot be created, or disallows writing.
            // * The database is not accessible, due to permissions or data protection when the device is locked.
            // * The device is out of space.
            // * The database could not be migrated to its latest schema version.
            // Check the error message to determine what the actual problem was.
            fatalError("Unresolved error \(error)")
        }
    }

    /// Creates an empty database for SwiftUI previews
    static func empty() -> AppDatabase {
        // Connect to an in-memory database
        // See https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/databaseconnections
        let dbQueue = try! DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        return try! AppDatabase(dbQueue)
    }

    /// Creates a database full of random players for SwiftUI previews
    static func random() -> AppDatabase {
        let appDatabase = empty()
        return appDatabase
    }

    /// 首次启动或初始化时默认预置 Tibo 好友（仅在全首次安装且未初始化时执行，用户主动删空后不会再复活）
    static func seedDefaultEntriesIfNeeded(in dbWriter: any DatabaseWriter, userDefaults: UserDefaults = .standard, force: Bool = false) {
        if !force && userDefaults.bool(forKey: "hasSeededDefaultEntries") {
            return
        }

        do {
            try dbWriter.write { db in
                let count = try Entry.fetchCount(db)
                if count == 0 {
                    let tibo = Entry(
                        type: .person,
                        name: "Tibo",
                        city: "PST (UTC−08:00)",
                        timezoneIdentifier: "Etc/GMT+8",
                        flag: nil,
                        photoData: nil
                    )
                    try tibo.insert(db)
                }
            }
            userDefaults.set(true, forKey: "hasSeededDefaultEntries")
        } catch {
            NSLog("Failed to seed default entry: \(error)")
        }
    }
}
