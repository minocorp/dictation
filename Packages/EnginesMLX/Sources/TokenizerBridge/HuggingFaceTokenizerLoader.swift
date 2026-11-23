import Foundation
import MLXHuggingFace
public import MLXLMCommon
import Tokenizers

// The macro expansion writes bare protocol types; this target leaves ExistentialAny off so the warning stays here.
public func makeHuggingFaceTokenizerLoader() -> any TokenizerLoader {
    #huggingFaceTokenizerLoader()
}
