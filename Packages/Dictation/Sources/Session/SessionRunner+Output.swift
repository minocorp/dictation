import Core

extension SessionRunner {
    func insert(_ id: DictationID, text: String, focus: FocusSnapshot) {
        let inserter = outputs.inserter
        spawn(id) { [weak self] in
            TimingLog.mark("insert-start", "characters=\(text.count)", for: id)
            let outcome = await inserter.insert(text, into: focus.target, focus: focus)
            TimingLog.mark("insert-end", "outcome=\(Self.name(of: outcome))", for: id)
            self?.send(.result(id, .inserted(outcome)))
        }
    }

    func copy(_ text: String) {
        let clipboard = outputs.clipboard
        spawnSerial(.storage) {
            await clipboard.copyTransient(text)
        }
    }

    func save(_ item: HistoryItem) {
        let history = environment.history
        spawnSerial(.storage) { [weak self] in
            let result = await Result.awaiting { () async throws(StoreError) in
                try await history.save(item)
            }
            self?.reportStore(result, id: item.id)
        }
    }

    func update(_ item: HistoryItem) {
        let history = environment.history
        spawnSerial(.storage) { [weak self] in
            let result = await Result.awaiting { () async throws(StoreError) in
                try await history.update(item)
            }
            self?.reportStore(result, id: item.id)
        }
    }

    private func reportStore(_ result: Result<Void, StoreError>, id: DictationID) {
        guard case .failure(let error) = result else { return }
        send(.result(id, .failed(.store(error))))
    }

    private static func name(of outcome: InsertOutcome) -> String {
        switch outcome {
        case .inserted: "inserted"
        case .copied: "copied"
        case .refused: "refused"
        }
    }
}
