import Core

extension Pending {
    var orderedIndices: [Int] { segments.keys.sorted() }

    var rawTranscript: String {
        Self.joined(orderedIndices.compactMap { segments[$0]?.rawText })
    }

    var cleanedTranscript: String {
        Self.joined(orderedIndices.compactMap { segments[$0]?.cleanedText })
    }

    var allSegmentsCleaned: Bool {
        segments.values.allSatisfy { $0.cleanedText != nil }
    }

    var isEdit: Bool {
        guard case .edit = kind else { return false }
        return true
    }

    var finalText: String {
        switch kind {
        case .edit:
            guard case .done(.success(let text)) = rewrite else { return "" }
            return text
        case .dictation, .editPending:
            return cleanedTranscript
        }
    }

    static func joined(_ texts: [String]) -> String {
        texts.filter { !$0.isEmpty }.joined(separator: " ")
    }

    mutating func record(_ segment: Segment) {
        segments[segment.index] = .recorded(segment)
        sampleCount = max(sampleCount, segment.startSample + segment.audio.count)
    }

    mutating func receive(transcription: Result<String, SpeechError>, at index: Int) {
        guard case .transcribing = segments[index], delivery != .canceled else { return }
        switch transcription {
        case .success(let raw): segments[index] = .transcribed(raw: raw)
        case .failure(let error): failure = .speech(error)
        }
    }

    mutating func receive(cleaning: Result<String, CleanupError>, at index: Int) {
        guard case .cleaning(let raw) = segments[index] else { return }
        switch cleaning {
        case .success(let text): segments[index] = .cleaned(raw: raw, text: text)
        case .failure: segments[index] = .cleaned(raw: raw, text: raw)
        }
    }

    func contextBefore(index: Int) -> String {
        let preceding = Self.joined((0..<index).compactMap { segments[$0]?.cleanedText })
        let text = preceding.isEmpty ? target?.textBefore ?? "" : preceding
        return String(text.suffix(SessionTiming.contextCharacterLimit))
    }
}
