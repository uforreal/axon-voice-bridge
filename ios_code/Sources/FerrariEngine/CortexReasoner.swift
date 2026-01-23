import Foundation

/**
 # CortexReasoner.swift
 # The Thinking Engine: Parse -> Search -> Apply -> Escalate -> Learn
 */
class CortexReasoner {
    private let firewall = VerificationLayer()
    private let router = ThalamusRouter()
    private var localKnowledge: [String: KnowledgeDomain] = [:] // Cached domains

    init() {
        loadDomains()
    }

    /**
     Main Entry Point for 'Thinking'
     */
    func process(input: String, completion: @escaping (String) -> Void) {
        
        // 1. PARSE: Extract Intent/Domain
        let toolType = router.routeIntent(text: input)
        print("🧠 Reasoner Step 1: Parsed Intent as \(toolType)")

        // 2 & 3. SEARCH LOCAL & APPLY PRINCIPLES
        if let localAnswer = searchLocalKnowledge(input, tool: toolType) {
            print("🧠 Reasoner Step 2/3: Local Knowledge Found (Confidence High)")
            completion(localAnswer)
            return
        }

        // 4. ESCALATE: Use External Tools
        print("🧠 Reasoner Step 4: Escalating to Tools...")
        escalate(input, toolType: toolType) { [weak self] externalResult, confidence, source, type in
            
            // 5. LEARN: Verify and Ingest
            let verification = self?.firewall.verify(claim: externalResult, type: type, source: source)
            
            if verification?.isValid == true {
                self?.ingest(fact: externalResult, type: type, domain: "General")
                completion(externalResult)
            } else {
                completion("[soft] I found something, but I don't trust the source enough to tell you. Let's verify it together.")
            }
        }
    }

    private func loadDomains() {
        // Since XcodeGen adds Resources as groups, files are flat in the bundle root.
        // We scan for all JSONs and try to decode them as KnowledgeDomain.
        guard let jsonFiles = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            print("⚠️ CortexReasoner: No JSON files found in bundle.")
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        for url in jsonFiles {
            do {
                let data = try Data(contentsOf: url)
                // Try decoding as KnowledgeDomain
                if let domain = try? decoder.decode(KnowledgeDomain.self, from: data) {
                    self.localKnowledge[domain.name] = domain
                    print("📚 Loaded Knowledge Domain: \(domain.name) from \(url.lastPathComponent)")
                }
            } catch {
                print("❌ Failed to load potential domain \(url.lastPathComponent): \(error)")
            }
        }
    }

    private func searchLocalKnowledge(_ query: String, tool: ThalamusRouter.Tool) -> String? {
        let normalizedQuery = query.lowercased()
        
        for domain in localKnowledge.values {
            // 1. Check Concepts
            if let concepts = domain.concepts {
                for (conceptName, conceptData) in concepts {
                    if normalizedQuery.contains(conceptName.lowercased()) {
                        return "[Local Knowledge: \(domain.name)] \(conceptData.definition)"
                    }
                }
            }
            
            // 2. Check Principles (if needed for reasoning, skipped for simple definition lookup)
        }
        
        return nil
    }

    private func escalate(_ query: String, toolType: ThalamusRouter.Tool, onResult: @escaping (String, Float, String, TruthClass) -> Void) {
        // This is where we call Gemini (The Agent) or Internet Search.
        // We set the TruthClass based on the response (e.g. Current Events -> SHAHADA)
        onResult("This is a verified fact from the web.", 0.9, "Google Search", .shahada)
    }

    private func ingest(fact: String, type: TruthClass, domain: String) {
        // Translates 'Human Language' -> 'Machine-Native JSON'
        // And saves to d:/Rufen/ferrari_tts/ios_code/Resources/Domains/
        print("💾 Reasoner Step 5: Learning... New fact ingested into \(domain).json")
    }
}
