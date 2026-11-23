@testable import EvalKit
import Foundation
import Testing

internal struct DatasetPageTests {
    private let json = """
        {"rows":[{"row_idx":0,"row":{"id":7,"audio":[{"src":"https://example.com/a.wav?x=1","type":"audio/wav"}],"text":"안녕"}}],"num_rows_total":457}
        """

    @Test
    func decodesAudioAndTextFields() throws {
        let page = try JSONDecoder().decode(DatasetPage.self, from: Data(json.utf8))
        #expect(page.total == 457)
        let row = try #require(page.rows.first?.row)
        guard case .audio(let url) = row["audio"], case .text(let text) = row["text"] else {
            Issue.record("unexpected row shape")
            return
        }
        #expect(url.pathExtension == "wav")
        #expect(text == "안녕")
    }
}
