public import Core
import Foundation
public import Observation

@MainActor
@Observable
public final class KeyRecorderModel {
    public private(set) var isRecording = false
    public private(set) var confirmations = 0

    @ObservationIgnored
    private let kind: KeyRecorderKind
    @ObservationIgnored
    private let capture: @MainActor () -> AsyncStream<RawKeyEvent>
    @ObservationIgnored
    private let defaultBinding: KeyBinding
    @ObservationIgnored
    private let commit: @MainActor (KeyBinding) -> Void
    @ObservationIgnored
    private var task: Task<Void, Never>?

    public let binding: () -> KeyBinding

    public init(
        kind: KeyRecorderKind,
        defaultBinding: KeyBinding,
        binding: @escaping () -> KeyBinding,
        capture: @escaping @MainActor () -> AsyncStream<RawKeyEvent>,
        commit: @escaping @MainActor (KeyBinding) -> Void,
    ) {
        self.kind = kind
        self.defaultBinding = defaultBinding
        self.binding = binding
        self.capture = capture
        self.commit = commit
    }

    isolated deinit {
        task?.cancel()
    }

    public var currentLabel: String { binding().label }
    public var isDefault: Bool { binding() == defaultBinding }
    var promptKey: LocalizedStringResource {
        kind == .dictateKey ? UIString.keyRecording : UIString.keyRecordingShortcut
    }

    public func begin() {
        guard !isRecording else { return }
        isRecording = true
        let events = capture()
        task = Task { [weak self] in
            for await event in events {
                guard let self, self.receive(event) else { continue }
                break
            }
            self?.finish()
        }
    }

    public func cancel() {
        task?.cancel()
        finish()
    }

    public func reset() {
        commit(defaultBinding)
    }

    func receive(_ event: RawKeyEvent) -> Bool {
        switch KeyCapture.outcome(for: event, kind: kind) {
        case .accepted(let accepted):
            commit(accepted)
            confirmations += 1
            return true
        case .cancelled:
            return true
        case .ignored:
            return false
        }
    }

    private func finish() {
        task = nil
        isRecording = false
    }
}
