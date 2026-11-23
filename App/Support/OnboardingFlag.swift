import Foundation

internal struct OnboardingFlag {
    private static let key = "onboardingCompleted"

    let defaults: UserDefaults

    var isCompleted: Bool {
        get { defaults.bool(forKey: Self.key) }
        nonmutating set { defaults.set(newValue, forKey: Self.key) }
    }
}
