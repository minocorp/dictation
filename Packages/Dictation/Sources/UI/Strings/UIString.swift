import Foundation

internal enum UIString {
    static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL),
        )
    }

    static func resource(interpolated value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(value, bundle: .atURL(Bundle.module.bundleURL))
    }

    static func string(_ resource: LocalizedStringResource) -> String {
        String(localized: resource)
    }
}
