import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class ThalamusEngine {
  static Map<String, dynamic>? _library;
  static final Random _random = Random();

  /// Load the JSON Library from assets
  static Future<void> loadLibrary() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/thalamus_library.json');
      _library = json.decode(jsonString);
      print("[THALAMUS] Library Loaded: ${_library?['meta']['version']}");
    } catch (e) {
      print("[THALAMUS ERROR] Could not load library: $e");
    }
  }

  /// The Calculator: Takes Vibe + Text -> Returns Response String
  static String process(String text, Map<String, dynamic> vibe) {
    if (_library == null) return "System initializing...";

    double energy = vibe['energy'] ?? 0.5;
    List<dynamic> protocols = _library!['protocols'];
    
    // Default fallback
    List<String> validTemplates = ["I see."];

    // logic: Find the matching protocol
    for (var protocol in protocols) {
      Map<String, dynamic> trigger = protocol['trigger'];
      
      bool match = false;
      
      // Check for High Energy Trigger
      if (trigger.containsKey('energy_min')) {
        if (energy >= trigger['energy_min']) match = true;
      }
      // Check for Low Energy Trigger
      else if (trigger.containsKey('energy_max')) {
        if (energy <= trigger['energy_max']) match = true;
      }
      // Default
      else if (trigger.containsKey('default') && trigger['default'] == true) {
         // Only use default if no other matches? 
         // For simplicity, we'll assume the loop finds the *first* specific match, 
         // so we should put default last in JSON or use a better selector.
         // Here we will specific check:
         match = true; 
      }

      if (match) {
        print("[THALAMUS] Matched Protocol: ${protocol['id']}");
        validTemplates = List<String>.from(protocol['templates']);
        break; // Stop at first match (Priority system)
      }
    }

    // "Calculate" the response (Random selection from the matched set)
    return validTemplates[_random.nextInt(validTemplates.length)];
  }
}
