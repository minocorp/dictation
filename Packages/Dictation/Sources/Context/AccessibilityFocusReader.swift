public import Core
import Foundation
public import Pasteboard

public actor AccessibilityFocusReader: FocusReader {
    private let queue = DispatchSerialQueue(
        label: "app.dictation.context.accessibility",
        qos: .userInitiated,
    )

    private let apps: any FrontmostAppSource
    private let focusedElements: any FocusedElementSource
    private let secureInput: any SecureInputSource
    private let selections: SelectionReader

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    public init(transaction: ClipboardTransaction) {
        self.init(
            apps: SystemFrontmostAppSource(),
            focusedElements: SystemFocusedElementSource(),
            secureInput: SystemSecureInputSource(),
            selections: SelectionReader(
                transaction: transaction,
                shortcuts: SystemShortcutPoster(),
            ),
        )
    }

    internal init(
        apps: any FrontmostAppSource,
        focusedElements: any FocusedElementSource,
        secureInput: any SecureInputSource,
        selections: SelectionReader,
    ) {
        self.apps = apps
        self.focusedElements = focusedElements
        self.secureInput = secureInput
        self.selections = selections
    }

    public func snapshot() async -> FocusSnapshot? {
        guard let target = apps.frontmost() else { return nil }
        return FocusSnapshotBuilder.build(
            target: target,
            focus: focusedElements.focusedElement(ofPID: target.pid),
            isSecureInputActive: secureInput.isSecureInputActive(),
        )
    }

    public func selection(maxCharacters: Int) async -> Selection {
        guard let target = apps.frontmost() else { return .unreadable }
        let focus = focusedElements.focusedElement(ofPID: target.pid)
        let isSecure = FocusSnapshotBuilder.isSecure(
            target: target,
            focus: focus,
            isSecureInputActive: secureInput.isSecureInputActive(),
        )
        return await selections.read(
            element: focus,
            isSecure: isSecure,
            maxCharacters: maxCharacters,
        )
    }
}
