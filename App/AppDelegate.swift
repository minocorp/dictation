import AppKit

@MainActor
internal final class AppDelegate: NSObject, NSApplicationDelegate {
    private var root: AppRoot?
    private var activity: (any NSObjectProtocol)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        activity = ResponsiveProcess.begin()
        #if DEBUG
        if let request = PipelineBenchmarkRequest.fromArguments() {
            Task {
                await PipelineBenchmark(core: AppCore.make(), request: request).run()
                exit(0)
            }
            return
        }
        #endif
        if SingleInstance.yieldToRunningInstance() {
            NSApp.terminate(nil)
            return
        }
        let root = AppRoot()
        self.root = root
        Task { await root.start() }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool,
    ) -> Bool {
        root?.showSettings()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
