import Foundation

internal enum OnboardingStep: Int, CaseIterable, Hashable {
    case microphone
    case accessibility
    case key
    case tryIt

    var title: LocalizedStringResource {
        switch self {
        case .microphone: UIString.obMicrophone
        case .accessibility: UIString.obAccessibility
        case .key: UIString.obKey
        case .tryIt: UIString.obTry
        }
    }
}
