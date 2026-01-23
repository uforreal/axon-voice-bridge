import Foundation
import GoogleGenerativeAI

/**
 # GeminiBrain.swift
 The "Intelligence" portion of the Ferrari.
 
 This class handles the connection to Google's Gemini 1.5 Flash.
 It uses streaming to ensure we get the first few words as fast as possible.
 */
class GeminiBrain {
    private let model: GenerativeModel
    
    init(apiKey: String) {
        // We use Gemini 1.5 Flash for the "Ferrari" because it's the fastest
        // and has the lowest latency for conversational AI.
        self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKey)
    }
    
    /**
     Sends a prompt to Gemini and streams the response.
     We split the response into sentences to send them to the TTS engine immediately.
     */
    func generateResponse(prompt: String, onSentenceReady: @escaping (String) -> Void) async throws {
        let chat = model.startChat()
        var currentSentence = ""
        
        // Start a streaming response
        let responseStream = chat.sendMessageStream(prompt)
        
        for try await chunk in responseStream {
            guard let text = chunk.text else { continue }
            currentSentence += text
            
            // Check for sentence boundaries (. ! ?)
            // This allows us to start the TTS for the FIRST sentence 
            // while Gemini is still thinking about the SECOND sentence.
            if let index = currentSentence.firstIndex(where: { ".!?".contains($0) }) {
                let sentence = String(currentSentence[...index]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    onSentenceReady(sentence)
                }
                currentSentence = String(currentSentence[currentSentence.index(after: index)...])
            }
        }
        
        // Handle any remaining text
        let remaining = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty {
            onSentenceReady(remaining)
        }
    }
}
