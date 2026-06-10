//
//  Kokoro-tts-lib
//

import Foundation

/// Produces Kokoro phoneme token inputs for an external inference engine (e.g. a Core ML port of the
/// Kokoro decoder) without loading the MLX model weights.
///
/// ``KokoroTTS`` runs the full MLX pipeline and loads the 327 MB weight set in its initializer. A consumer
/// that only needs grapheme-to-phoneme conversion and tokenization — because it runs the actual synthesis
/// elsewhere — would otherwise pay that whole cost. ``KokoroPhonemeTokenizer`` exposes just the G2P and
/// vocabulary-tokenization stages, which need only the bundled config and the (Apache-2.0, pure-Swift)
/// Misaki G2P.
///
/// The produced `inputIds` are wrapped with the BOS/EOS padding token (`0`) at both ends — matching the
/// sequence ``KokoroTTS`` feeds its own model — and `attentionMask` is all ones for that sequence (a caller
/// that pads to a fixed bucket length sets the padded positions to `0`). `phonemeTokenCount` is the number
/// of phoneme tokens *excluding* the BOS/EOS wrap; it is the index a caller uses to select the per-length
/// reference style vector (`ref_s`) from a Kokoro voice pack.
public final class KokoroPhonemeTokenizer {

  // MARK: Lifecycle

  /// - Parameter g2p: Grapheme-to-phoneme engine. Defaults to Misaki (pure-Swift, Apache-2.0).
  public init(g2p: G2P = .misaki) throws {
    // Ensure the bundled Kokoro config (and its vocab) is loaded so `Tokenizer` can map phonemes to IDs.
    _ = KokoroConfig.loadConfig()
    guard let processor = try? G2PFactory.createG2PProcessor(engine: g2p) else {
      throw G2PProcessorError.processorNotInitialized
    }
    g2pProcessor = processor
  }

  // MARK: Public

  public enum TokenizationError: Error {
    /// The phonemized text exceeds Kokoro's maximum token count (`KokoroTTS.Constants.maxTokenCount`).
    case tooManyTokens
  }

  /// Token inputs for an external (e.g. Core ML) Kokoro pipeline.
  ///
  /// - Parameters:
  ///   - text: Text to synthesize.
  ///   - language: Pronunciation variant (e.g. `.enUS`, `.enGB`).
  /// - Returns: BOS/EOS-wrapped phoneme token IDs, the matching all-ones attention mask, and the unwrapped
  ///   phoneme token count for `ref_s` voice-pack indexing.
  public func tokens(
    for text: String,
    language: Language
  ) throws -> (inputIds: [Int32], attentionMask: [Int32], phonemeTokenCount: Int) {
    try setLanguageIfNeeded(language)

    let (phonemizedText, _) = try g2pProcessor.process(input: text)

    let phonemeIds = Tokenizer.tokenize(phonemizedText: phonemizedText)
    guard phonemeIds.count <= KokoroTTS.Constants.maxTokenCount else {
      throw TokenizationError.tooManyTokens
    }

    let wrapped = [0] + phonemeIds + [0]
    return (
      inputIds: wrapped.map { Int32($0) },
      attentionMask: [Int32](repeating: 1, count: wrapped.count),
      phonemeTokenCount: phonemeIds.count
    )
  }

  // MARK: Private

  private let g2pProcessor: G2PProcessor
  private var chosenLanguage: Language = .none

  private func setLanguageIfNeeded(_ language: Language) throws {
    guard chosenLanguage != language else {
      return
    }
    try g2pProcessor.setLanguage(language)
    chosenLanguage = language
  }
}
