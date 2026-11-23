import Clocks
import Core
import Foundation
@testable import Permissions
import Testing

internal struct SystemPermissionMonitorTests {
    private let system = FakePermissionSystem()
    private let clock = Clocks.TestClock<Duration>()
    private let monitor: SystemPermissionMonitor

    init() {
        monitor = SystemPermissionMonitor(
            system: system,
            clock: clock,
            onboardingInterval: .seconds(1),
            idleInterval: .seconds(2),
        )
    }

    @Test
    func emitsInitialStatusThenOnlyChanges() async {
        var iterator = monitor.status.makeAsyncIterator()
        #expect(
            await iterator.next()
                == PermissionStatus(microphone: .notDetermined, isAccessibilityTrusted: false)
        )

        system.microphone = .granted
        await clock.advance(by: .seconds(2))
        #expect(
            await iterator.next()
                == PermissionStatus(microphone: .granted, isAccessibilityTrusted: false)
        )

        await clock.advance(by: .seconds(2))
        system.isTrusted = true
        await clock.advance(by: .seconds(2))
        #expect(
            await iterator.next()
                == PermissionStatus(microphone: .granted, isAccessibilityTrusted: true)
        )
    }

    @Test
    func pollsEveryTwoSecondsUnlessOnboardingIsVisible() {
        #expect(monitor.currentInterval == .seconds(2))
        monitor.setOnboardingVisible(true)
        #expect(monitor.currentInterval == .seconds(1))
        monitor.setOnboardingVisible(false)
        #expect(monitor.currentInterval == .seconds(2))
    }

    @Test
    func requestsMicrophoneThroughTheSystem() async {
        await monitor.request(.microphone)
        #expect(system.microphoneRequests == 1)
        #expect(system.prompts == 0)
    }

    @Test
    func requestsAccessibilityThroughThePrompt() async {
        await monitor.request(.accessibility)
        #expect(system.prompts == 1)
        #expect(system.microphoneRequests == 0)
    }

    @Test(arguments: [
        (Permission.microphone, "Privacy_Microphone"),
        (Permission.accessibility, "Privacy_Accessibility"),
    ])
    func settingsLinksTryTheCurrentPaneThenTheLegacyOne(permission: Permission, anchor: String) {
        #expect(
            permission.settingsURLs.map(\.absoluteString) == [
                "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(anchor)",
                "x-apple.systempreferences:com.apple.preference.security?\(anchor)",
            ]
        )
    }

    @Test
    func openSettingsStopsAtTheFirstLinkThatOpens() async {
        system.urlsThatOpen = Set(Permission.microphone.settingsURLs)
        await monitor.openSettings(for: .microphone)
        #expect(system.opened == [Permission.microphone.settingsURLs[0]])
    }

    @Test
    func openSettingsFallsBackToTheLegacyLink() async {
        system.urlsThatOpen = [Permission.accessibility.settingsURLs[1]]
        await monitor.openSettings(for: .accessibility)
        #expect(system.opened == Permission.accessibility.settingsURLs)
    }

    @Test
    func openSettingsTriesBothLinksWhenNeitherOpens() async {
        await monitor.openSettings(for: .accessibility)
        #expect(system.opened.count == 2)
    }
}
