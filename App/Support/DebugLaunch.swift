#if DEBUG
import AppKit
import Core
import Foundation
import UI

@MainActor
internal enum DebugLaunch {
    private enum Target: String {
        case settingsGeneral = "settings-general"
        case settingsDictionary = "settings-dictionary"
        case settingsModels = "settings-models"
        case settingsHistory = "settings-history"
        case settingsAbout = "settings-about"
        case history
        case menu
    }

    private struct SeedItem {
        let bundleID: String
        let appName: String
        let rawText: String
        let finalText: String
        let status: HistoryItem.Status
        let age: TimeInterval
    }

    private static let seedItems = [
        SeedItem(
            bundleID: "com.apple.Notes",
            appName: "Notes",
            rawText: "um so tomorrow at 3 pm no 4 pm we meet at the studio",
            finalText: "Tomorrow at 4 pm we meet at the studio.",
            status: .inserted,
            age: 300,
        ),
        SeedItem(
            bundleID: "com.apple.Safari",
            appName: "Safari",
            rawText: "이거 리액트 유즈 이펙트에서 처리해줘",
            finalText: "이거 React useEffect에서 처리해줘.",
            status: .copied,
            age: 4_000,
        ),
        SeedItem(
            bundleID: "com.apple.TextEdit",
            appName: "TextEdit",
            rawText: "hello this was canceled",
            finalText: "Hello, this was canceled.",
            status: .canceled,
            age: 90_000,
        ),
        SeedItem(
            bundleID: "com.apple.mail",
            appName: "Mail",
            rawText: "thanks for the update i will review it tonight",
            finalText: "Thanks for the update. I will review it tonight.",
            status: .pending,
            age: 200_000,
        ),
    ]

    static var seedsHistory: Bool { CommandLine.arguments.contains("--seed-history") }

    static func applyAppearance() {
        guard let value = argument("--appearance=") else { return }
        NSApp.appearance = NSAppearance(named: value == "dark" ? .darkAqua : .aqua)
    }

    static func present(_ name: String, on actions: AppActions, status: StatusItemController) {
        guard let target = Target(rawValue: name) else { return }
        switch target {
        case .settingsGeneral: actions.showSettings(.general)
        case .settingsDictionary: actions.showSettings(.dictionary)
        case .settingsModels: actions.showSettings(.models)
        case .settingsHistory: actions.showSettings(.history)
        case .settingsAbout: actions.showSettings(.about)
        case .history: actions.showHistory()
        case .menu: status.popUpMenu()
        }
        Task {
            try? await ContinuousClock().sleep(for: .milliseconds(500))
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    static var target: String? { argument("--show=") }

    static func seed(_ store: any HistoryStore) async {
        let now = Date()
        for seed in seedItems {
            let item = HistoryItem(
                id: DictationID(),
                date: now.addingTimeInterval(-seed.age),
                appBundleID: seed.bundleID,
                appName: seed.appName,
                kind: .dictation,
                rawText: seed.rawText,
                finalText: seed.finalText,
                instruction: nil,
                audioURL: nil,
                duration: .seconds(6),
                status: seed.status,
            )
            try? await store.save(item)
        }
    }

    private static func argument(_ prefix: String) -> String? {
        CommandLine.arguments.first { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
    }
}
#endif
