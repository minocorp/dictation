import Core
import Foundation

internal struct Pending: Equatable, Sendable {
    var id: DictationID
    var date: Date
    var source: Source
    var delivery: Delivery
    var kind = Kind.dictation
    var stage: Stage
    var target: FocusSnapshot?
    var isTargetKnown: Bool
    var segments: [Int: SegmentState] = [:]
    var segmentsEnded = false
    var audioURL: URL?
    var isAudioClosed: Bool
    var sampleCount = 0
    var failure: Failure?
    var rewrite = Rewrite.notStarted
    var existing: HistoryItem?
    var wasTap = false

    init(id: DictationID, date: Date, source: Source, delivery: Delivery) {
        self.id = id
        self.date = date
        self.source = source
        self.delivery = delivery
        isTargetKnown = delivery == .background
        switch source {
        case .live:
            stage = .running
            isAudioClosed = false
        case .audio(let url):
            stage = .waiting
            audioURL = url
            isAudioClosed = true
        case .pasteLast:
            stage = .waiting
            isAudioClosed = true
        }
    }

    var isForeground: Bool {
        switch delivery {
        case .insert: true
        case .keepAsLast, .canceled, .background: false
        }
    }

    var isHoldable: Bool {
        guard delivery == .insert, stage != .delivering else { return false }
        switch source {
        case .live, .audio: return true
        case .pasteLast: return false
        }
    }

    var keptStatus: HistoryItem.Status {
        guard let status = existing?.status else { return .recovered }
        switch status {
        case .inserted, .copied, .canceled, .refused: return status
        case .pending, .recovered, .failed: return .recovered
        }
    }
}
