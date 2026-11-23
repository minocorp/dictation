import Core
@testable import Hotkeys
import Testing

internal struct GlobeSettingReaderTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let usageType: Int?
        let sourceKinds: [String]
        let usage: GlobeUsage
        let recommendedKey: KeyBinding

        var testDescription: String { name }
    }

    private static let koreanSetup = [
        "Keyboard Layout", "Input Mode", "Keyboard Input Method", "Non Keyboard Input Method",
    ]
    private static let singleSetup = ["Keyboard Layout", "Non Keyboard Input Method"]

    static let cases = [
        Case(
            name: "0 is do nothing",
            usageType: 0,
            sourceKinds: koreanSetup,
            usage: .doNothing,
            recommendedKey: .fn,
        ),
        Case(
            name: "1 changes input source",
            usageType: 1,
            sourceKinds: singleSetup,
            usage: .changeInputSource,
            recommendedKey: .rightOption,
        ),
        Case(
            name: "2 shows emoji",
            usageType: 2,
            sourceKinds: singleSetup,
            usage: .showEmojiAndSymbols,
            recommendedKey: .fn,
        ),
        Case(
            name: "3 starts dictation",
            usageType: 3,
            sourceKinds: singleSetup,
            usage: .startDictation,
            recommendedKey: .fn,
        ),
        Case(
            name: "unknown value is kept",
            usageType: 9,
            sourceKinds: [],
            usage: .other(9),
            recommendedKey: .fn,
        ),
        Case(
            name: "unset with several input sources switches input",
            usageType: nil,
            sourceKinds: koreanSetup,
            usage: .changeInputSource,
            recommendedKey: .rightOption,
        ),
        Case(
            name: "unset with one input source shows emoji",
            usageType: nil,
            sourceKinds: singleSetup,
            usage: .showEmojiAndSymbols,
            recommendedKey: .fn,
        ),
        Case(
            name: "unset without sources shows emoji",
            usageType: nil,
            sourceKinds: [],
            usage: .showEmojiAndSymbols,
            recommendedKey: .fn,
        ),
    ]

    @Test(arguments: cases)
    func readsSetting(testCase: Case) {
        let reader = GlobeSettingReader(
            preferences: FakeGlobePreferences(
                usageType: testCase.usageType,
                sourceKinds: testCase.sourceKinds,
            )
        )
        let setting = reader.read()
        #expect(setting.usage == testCase.usage)
        #expect(setting.recommendedDictateKey == testCase.recommendedKey)
        #expect(setting.isFnFree == (testCase.usage == .doNothing))
    }
}
