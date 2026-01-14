import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class ConceptGraph {
  static Map<String, dynamic>? _graph;
  static final Random _random = Random();

  /// Load the Neural Web
  static Future<void> loadMemory() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/concept_graph.json');
      _graph = json.decode(jsonString);
      print("[CORTEX] Concept Graph Loaded: ${_graph?['concepts'].length} concepts");
    } catch (e) {
      print("[CORTEX ERROR] Failed to load brain: $e");
    }
  }

  /// The "Spark" function: Generates a thought based on Impulse
  static String generateThought(Map<String, dynamic> vibe) {
    if (_graph == null) return "System initializing...";

    // 1. Determine the "Active Concept" based on Vibe
    String activeConcept = _resolveImpulse(vibe);
    print("[CORTEX] Active Concept: $activeConcept");

    // 2. Fetch the Web of Words for this concept
    Map<String, dynamic> node = _graph!['concepts'][activeConcept];
    if (node == null) return "I'm listening.";

    // 3. Select a Grammar Template
    List<dynamic> templates = _graph!['grammar_templates'];
    String template = templates[_random.nextInt(templates.length)];

    // 4. Fill the slots (The Assembly)
    return _assembleSentence(template, node);
  }

  static String _resolveImpulse(Map<String, dynamic> vibe) {
    double energy = vibe['energy'] ?? 0.5;
    double density = vibe['density'] ?? 0.0; // Assume density maps to tempo

    // Simple Vector Mapping
    if (energy > 0.7) return "excitement";
    if (energy < 0.3) return "exhaustion";
    if (density > 0.5) return "curiosity"; // Fast speech = Curiosity?
    
    // Default fallback to affection (The Safe Base)
    return "affection"; 
  }

  static String _assembleSentence(String template, Map<String, dynamic> node) {
    String result = template;

    // Helper to pick random word from list
    String pick(String key) {
      if (!node.containsKey(key)) return "";
      List<dynamic> words = node[key];
      return words[_random.nextInt(words.length)];
    }

    result = result.replaceAll("{exclamation}", pick("exclamations"));
    result = result.replaceAll("{adjective}", pick("adjectives"));
    result = result.replaceAll("{verb}", pick("verbs"));

    return result;
  }
}
