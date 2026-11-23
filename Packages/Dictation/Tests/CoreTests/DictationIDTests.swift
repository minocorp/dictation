import Core
import Testing

internal struct DictationIDTests {
    @Test
    func stemRoundTrips() {
        let id = DictationID()
        #expect(DictationID(stem: id.stem) == id)
    }

    @Test
    func invalidStemIsRejected() {
        #expect(DictationID(stem: "not-a-uuid") == nil)
    }

    @Test
    func newIDsDiffer() {
        #expect(DictationID() != DictationID())
    }
}
