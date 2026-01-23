import Foundation

/**
 # CortexModels.swift
 # The 'Solid Basis' of Knowledge
 */

enum TruthClass: String, Codable {
    case haq      = "HAQ"       // Absolute (Physics/Math/Logic)
    case urf      = "URF"       // Convention (Customs/Borders)
    case shahada  = "SHAHADA"   // Testimony (History/News)
    case ilm      = "ILM"       // Methodological (Science/Engineering)
}

struct Confidence: Codable {
    var score: Float           // 0.0 to 1.0
    var expiration: Date?
    var decayRate: Float?      // 0.1 per month, etc.
    var truthType: TruthClass
    
    static var absolute: Confidence {
        return Confidence(score: 1.0, expiration: nil, decayRate: nil, truthType: .haq)
    }
}

struct Principle: Codable {
    let statement: String
    let logic: String          // The 'If/Then' rule
    let domain: String
    var confidence: Confidence
}

struct Concept: Codable {
    let definition: String
    let principles: [String]
    let relationships: [String: String]
}

/**
 # Domain.json Structure
 */
struct KnowledgeDomain: Codable {
    var name: String
    var concepts: [String: Concept]?
    var procedures: [String: [String]]?
    var commonErrors: [String: String]? // Symptom -> Fix
    var shortcuts: [String: String]?
    var principles: [Principle]?
}
