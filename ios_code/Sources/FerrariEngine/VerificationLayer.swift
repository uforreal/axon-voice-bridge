import Foundation

/**
 # VerificationLayer.swift
 # The Epistemological Firewall
 */
class VerificationLayer {
    
    struct Anchor {
        let name: String
        let type: TruthClass
        let reference: String
    }
    
    // Fixed reference points: Nothing from the internet can contradict these.
    private let anchors: [String: Anchor] = [
        "gravity": Anchor(name: "Gravity", type: .haq, reference: "9.81 m/s^2"),
        "math":    Anchor(name: "Axiomatic Math", type: .haq, reference: "Non-contradictory logic"),
        "time":    Anchor(name: "UTC", type: .haq, reference: "Atomic Clock")
    ]
    
    /**
     Determines if a new claim is accepted into the CORTEX.
     */
    func verify(claim: String, type: TruthClass, source: String) -> (isValid: Bool, confidence: Float) {
        
        switch type {
        case .haq:
            // Absolute check: If it violates physics or logic, 0% confidence, Hard Reject.
            if violatesAnchors(claim) {
                print("🚨 HAQ VIOLATION: Claim rejected.")
                return (false, 0.0)
            }
            return (true, 1.0)
            
        case .urf:
            // Convention check: Requires context (e.g. current date/region)
            return (true, 0.95)
            
        case .shahada:
            // Testimony check: Does the source have credibility?
            let confidence = calculateSourceCredibility(source)
            return (confidence > 0.7, confidence)
            
        case .ilm:
            // Methodological check: Is it falsifiable?
            return (true, 0.85)
        }
    }
    
    private func violatesAnchors(_ claim: String) -> Bool {
        // Basic logic: Checks if claim contradicts fixed HAQ anchors.
        // Example: If claim contains "perpetual motion" -> True (Violation)
        let c = claim.lowercased()
        if c.contains("perpetual motion") || c.contains("gravity is fake") {
            return true
        }
        return false
    }
    
    private func calculateSourceCredibility(_ source: String) -> Float {
        // Higher confidence for official manuals, lower for blogs.
        if source.contains("official") || source.contains(".gov") || source.contains(".edu") {
            return 0.95
        }
        return 0.5
    }
}
