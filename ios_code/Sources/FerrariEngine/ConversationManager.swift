import Foundation
import Combine

/**
 # ConversationManager.swift (The Sovereign Edition)
 # This is the Final Captain of the Ferrari.
 */
class ConversationManager: ObservableObject {
    @Published var state: String = "Idle"
    @Published var aiResponse: String = ""
    
    private let cortex = CortexReasoner() // The new Sovereign Brain
    private let engine: FerrariEngine
    private let streamer: FerrariAudioStreamer
    private let tokenizer: KokoroTokenizer
    private let g2p = G2PProvider()
    
    init() throws {
        self.engine = try FerrariEngine()
        self.streamer = FerrariAudioStreamer()
        self.tokenizer = KokoroTokenizer()
    }
    
    func userSpoke(text: String) {
        self.state = "Thinking (CORTEX)..."
        
        // CORTEX decides everything (Local, Web, or Cloud)
        cortex.process(input: text) { [weak self] response in
            self?.vocalize(response)
        }
    }
    
    private func vocalize(_ text: String) {
        // Step 1: Phonemize (Solid Basis)
        let phonemes = g2p.getPhonemes(for: text)
        
        // Step 2: Tokenize (114-token Official Map)
        let tokenIds = tokenizer.tokenize(phonemes)
        
        // Step 3: Speak (ANE Powered)
        engine.speak64(tokenIds) { [weak self] audioBuffer in
            self?.streamer.pushAudio(audioBuffer)
            DispatchQueue.main.async {
                self?.state = "Speaking..."
                self?.aiResponse = text
            }
        }
    }
}
