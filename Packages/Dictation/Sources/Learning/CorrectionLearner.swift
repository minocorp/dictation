public import Core
import Foundation
import os

public struct CorrectionLearner: Sendable {
    private static let watchLimit: Duration = .seconds(60)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "",
        category: "Learning",
    )

    private let words: any WordStore
    private let watcher: any FieldWatching
    private let clock: any Clock<Duration>

    public init(words: any WordStore) {
        self.init(words: words, watcher: AccessibilityFieldWatcher(), clock: ContinuousClock())
    }

    internal init(words: any WordStore, watcher: any FieldWatching, clock: any Clock<Duration>) {
        self.words = words
        self.watcher = watcher
        self.clock = clock
    }

    public func observe(inserted text: String, into target: TargetApp, focus: FocusSnapshot) async {
        guard !focus.isSecure, let field = await watcher.watchFocusedField(ofPID: target.pid) else {
            return
        }
        let finalText = await finalText(of: field, inserted: text)
        await field.close()
        guard let (baseline, final) = finalText, !Task.isCancelled else { return }
        await record(CorrectionDiff.respellings(inserted: text, baseline: baseline, final: final))
    }

    private func finalText(
        of field: any WatchedField,
        inserted text: String,
    ) async -> (baseline: String, final: String)? {
        guard let baseline = await field.text(),
            InsertedRegionLocator.locate(text, in: baseline) != nil
        else { return nil }
        let latest = await waitForEnd(of: field, startingFrom: baseline)
        guard let last = await field.text(), CorrectionDiff.retainsBaseline(baseline, in: last)
        else { return (baseline, latest) }
        return (baseline, last)
    }

    private func waitForEnd(
        of field: any WatchedField,
        startingFrom baseline: String,
    ) async
        -> String
    {
        let (merged, continuation) = AsyncStream.makeStream(of: FieldEvent.self)
        let forwarding = Task {
            for await event in field.events { continuation.yield(event) }
            continuation.yield(.focusLeft)
        }
        let clock = clock
        let timer = Task {
            guard await clock.sleepUnlessCancelled(for: Self.watchLimit) else { return }
            continuation.yield(.timedOut)
        }
        var latest = baseline
        for await event in merged {
            guard event == .valueChanged else { break }
            if let text = await field.text(), CorrectionDiff.retainsBaseline(baseline, in: text) {
                latest = text
            }
        }
        forwarding.cancel()
        timer.cancel()
        continuation.finish()
        return latest
    }

    private func record(_ respellings: [Respelling]) async {
        for respelling in respellings {
            do {
                _ = try await words.recordCorrection(
                    from: respelling.original,
                    to: respelling.corrected,
                )
            } catch {
                Self.logger.error("recording a correction failed")
                return
            }
        }
    }
}
