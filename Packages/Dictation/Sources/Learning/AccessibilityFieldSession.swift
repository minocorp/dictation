// AXUIElement and AXObserver are CF handles that Apple has not marked Sendable.
@preconcurrency import ApplicationServices

private let eventForNotification: [String: FieldEvent] = [
    kAXValueChangedNotification: .valueChanged,
    kAXFocusedUIElementChangedNotification: .focusLeft,
    kAXUIElementDestroyedNotification: .focusLeft,
    kAXApplicationDeactivatedNotification: .appDeactivated,
]

private let observerCallback: AXObserverCallback = { _, _, notification, refcon in
    guard let refcon, let event = eventForNotification[notification as String] else { return }
    Unmanaged<ObserverCallbackBox>.fromOpaque(refcon).takeUnretainedValue()
        .continuation.yield(event)
}

internal actor AccessibilityFieldSession: WatchedField {
    nonisolated let events: AsyncStream<FieldEvent>

    private let field: AXUIElement
    private let continuation: AsyncStream<FieldEvent>.Continuation
    private let box: Unmanaged<ObserverCallbackBox>
    private var observer: AXObserver?

    init(pid: Int32, application: AXUIElement, field: AXUIElement) {
        let (events, continuation) = AsyncStream.makeStream(
            of: FieldEvent.self,
            bufferingPolicy: .bufferingNewest(1),
        )
        self.events = events
        self.continuation = continuation
        self.field = field
        box = Unmanaged.passRetained(ObserverCallbackBox(continuation: continuation))
        observer = Self.makeObserver(pid: pid, application: application, field: field, box: box)
    }

    func text() async -> String? {
        guard !AccessibilityFieldWatcher.isSecure(field) else { return nil }
        return AccessibilityFieldWatcher.value(of: field)
    }

    func close() async {
        if let observer {
            let source = AXObserverGetRunLoopSource(observer)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            CFRunLoopSourceInvalidate(source)
        }
        observer = nil
        continuation.finish()
        let box = box
        await MainActor.run { box.release() }
    }

    private static func makeObserver(
        pid: Int32,
        application: AXUIElement,
        field: AXUIElement,
        box: Unmanaged<ObserverCallbackBox>,
    ) -> AXObserver? {
        var created: AXObserver?
        guard AXObserverCreate(pid, observerCallback, &created) == .success, let created else {
            return nil
        }
        let refcon = box.toOpaque()
        let registrations: [(AXUIElement, String)] = [
            (field, kAXValueChangedNotification),
            (field, kAXUIElementDestroyedNotification),
            (application, kAXFocusedUIElementChangedNotification),
            (application, kAXApplicationDeactivatedNotification),
        ]
        for (element, notification) in registrations {
            AXObserverAddNotification(created, element, notification as CFString, refcon)
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .defaultMode)
        return created
    }
}
