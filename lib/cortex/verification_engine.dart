enum TruthClass { haq, urf, shahada, ilm, garbage }

class VerificationEngine {
  // 1. HAQ ANCHORS (Immutable)
  static final List<String> haqAnchors = [
    "physics", "gravity", "math", "biology", "thermodynamics"
  ];
  
  // 2. SHAHADA (Credible Sources)
  static final List<String> trustedDomains = [
    "wikipedia.org", "britannica.com", "edu", "gov", "reuters.com", "apnews.com"
  ];

  static TruthClass verify(String claim, String sourceUrl) {
    String lowerClaim = claim.toLowerCase();
    
    // 1. HAQ CHECK (Does it violate fundamental laws?)
    if (lowerClaim.contains("earth is flat") || 
        lowerClaim.contains("perpetual motion") ||
        lowerClaim.contains("cure") && lowerClaim.contains("miracle")) {
      print("[VERIFIER] Rejected HAQ violation: $claim");
      return TruthClass.garbage;
    }

    // 2. SHAHADA CHECK (Source Credibility)
    bool isTrusted = false;
    for (String domain in trustedDomains) {
      if (sourceUrl.contains(domain)) {
        isTrusted = true;
        break;
      }
    }
    
    if (!isTrusted) {
      print("[VERIFIER] Rejected SHAHADA violation (Source): $sourceUrl");
      return TruthClass.garbage; 
    }

    // 3. ILM CHECK (Methodology - Simplified to 'consensus' keywords for now)
    // In a real system, this would check for 'study', 'peer review', 'data'.
    
    return TruthClass.shahada; // Accepted as Witnessed Truth
  }
}
