import Foundation

/**
 # GeminiBrain.swift (Stub Edition)
 
 This is a stub for the Gemini Brain.
 In a full implementation, this would use the GoogleGenerativeAI SDK via SPM.
 For now, CORTEX handles all reasoning locally.
 */
class GeminiBrain {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
        print("🧠 Gemini Brain initialized (Stub Mode - CORTEX is handling reasoning locally).")
    }
    
    func generateResponse(prompt: String, onSentence: @escaping (String) -> Void) async throws {
        // In Stub Mode, we just echo back a placeholder.
        // The real implementation would stream from the Gemini API.
        onSentence("[soft] I am currently running in offline mode. CORTEX is handling your request locally.")
    }
}
