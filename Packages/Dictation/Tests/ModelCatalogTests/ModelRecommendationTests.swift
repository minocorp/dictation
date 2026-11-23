import Core
import Foundation
@testable import ModelCatalog
import Testing

internal struct ModelRecommendationTests {
    private struct Case: Sendable {
        let ramGB: Int
        let languages: [String]
        let speech: String
        let cleanup: String
    }

    private static let cases = [
        Case(
            ramGB: 8,
            languages: ["ko"],
            speech: "apple-speechanalyzer",
            cleanup: "apple-foundation-models",
        ),
        Case(
            ramGB: 15,
            languages: ["en"],
            speech: "apple-speechanalyzer",
            cleanup: "apple-foundation-models",
        ),
        Case(
            ramGB: 16,
            languages: ["ko", "en"],
            speech: "qwen3-asr-0.6b-8bit",
            cleanup: "qwen3.5-4b-4bit",
        ),
        Case(
            ramGB: 23,
            languages: ["en"],
            speech: "qwen3-asr-0.6b-8bit",
            cleanup: "qwen3.5-4b-4bit",
        ),
        Case(
            ramGB: 24,
            languages: ["ko"],
            speech: "qwen3-asr-1.7b-8bit",
            cleanup: "qwen3.5-4b-4bit",
        ),
        Case(
            ramGB: 64,
            languages: ["en", "ko"],
            speech: "qwen3-asr-1.7b-8bit",
            cleanup: "qwen3.5-4b-4bit",
        ),
        Case(
            ramGB: 16,
            languages: ["ja"],
            speech: "apple-speechanalyzer",
            cleanup: "qwen3.5-4b-4bit",
        ),
        Case(
            ramGB: 32,
            languages: ["ko", "fr"],
            speech: "apple-speechanalyzer",
            cleanup: "qwen3.5-4b-4bit",
        ),
        Case(ramGB: 16, languages: [], speech: "qwen3-asr-0.6b-8bit", cleanup: "qwen3.5-4b-4bit"),
    ]

    @Test(arguments: cases)
    private func recommendsByTierAndLanguages(_ testCase: Case) throws {
        let manifest = try ModelManifest.load(from: ManifestFixtures.realManifestURL)
        let profile = MachineProfile(
            ramGB: testCase.ramGB,
            languages: testCase.languages.map { Locale(identifier: $0) },
        )
        let picked = ModelRecommendation.pick(from: manifest.models, profile: profile)
        #expect(picked.speech.id == testCase.speech)
        #expect(picked.cleanup.id == testCase.cleanup)
    }

    @Test(arguments: [
        (0, RAMTier.ram8), (15, .ram8), (16, .ram16), (23, .ram16), (24, .ram24), (128, .ram24),
    ])
    func tierBoundaries(ramGB: Int, tier: RAMTier) {
        #expect(ModelRecommendation.tier(ramGB: ramGB) == tier)
    }

    @Test
    func regionalLocaleCountsAsItsLanguage() {
        let entry = ManifestFixtures.entry()
        #expect(ModelRecommendation.covers(entry, languages: [Locale(identifier: "ko_KR")]))
    }

    @Test
    func libraryRecommendationUsesItsProfile() throws {
        let manifest = try ModelManifest.load(from: ManifestFixtures.realManifestURL)
        let fixtures = DownloadFixtures()
        let library = ManifestModelLibrary(
            manifest: manifest,
            profile: MachineProfile(ramGB: 16, languages: [Locale(identifier: "en")]),
            storage: fixtures.storage,
            downloader: fixtures.makeDownloader(),
        )
        #expect(library.recommended().cleanup.id == "qwen3.5-4b-4bit")
        #expect(library.entries(stage: .speech).first == .appleSpeechAnalyzer)
        #expect(library.entries(stage: .cleanup).count == 4)
    }
}
