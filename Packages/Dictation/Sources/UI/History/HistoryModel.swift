public import AppKit
public import Core
public import Observation

@MainActor
@Observable
public final class HistoryModel {
    public var query = ""
    public private(set) var items: [HistoryItem] = []
    var expanded: DictationID?
    var shownOriginals: Set<DictationID> = []
    var dictionaryCandidate: HistoryItem?

    @ObservationIgnored
    private let store: any HistoryStore
    @ObservationIgnored
    private let actions: HistoryActions
    @ObservationIgnored
    private let calendar: Calendar
    @ObservationIgnored
    private var icons: [String: NSImage] = [:]

    public let dictionary: DictionaryModel

    public init(
        store: any HistoryStore,
        dictionary: DictionaryModel,
        actions: HistoryActions,
        calendar: Calendar,
    ) {
        self.store = store
        self.dictionary = dictionary
        self.actions = actions
        self.calendar = calendar
    }

    var sections: [HistorySection] {
        HistorySection.group(items, calendar: calendar)
    }

    var now: Date { Date() }

    public func watch() async {
        for await list in actions.observe(query) {
            items = list
        }
    }

    func toggleExpanded(_ item: HistoryItem) {
        expanded = expanded == item.id ? nil : item.id
    }

    func toggleOriginal(_ item: HistoryItem) {
        if shownOriginals.contains(item.id) {
            shownOriginals.remove(item.id)
        } else {
            shownOriginals.insert(item.id)
        }
    }

    func copy(_ item: HistoryItem) {
        actions.copy(item.finalText.isEmpty ? item.rawText : item.finalText)
    }

    func canRetry(_ item: HistoryItem) -> Bool {
        item.audioURL != nil
    }

    func retry(_ item: HistoryItem) async {
        await actions.retry(item.id)
    }

    func delete(_ item: HistoryItem) async {
        do {
            try await store.delete(id: item.id)
        } catch {
            UILog.failure("history delete", error)
        }
    }

    func icon(for bundleID: String) -> NSImage? {
        if let cached = icons[bundleID] { return cached }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let image = NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false))
        icons[bundleID] = image
        return image
    }
}
