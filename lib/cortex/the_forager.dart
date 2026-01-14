import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'verification_engine.dart';

class TheForager {
  HeadlessInAppWebView? _headlessWebView;
  Completer<String?>? _searchCompleter;

  Future<String?> forage(String query) async {
    _searchCompleter = Completer<String?>();
    
    // 1. Construct Search Query
    // We use DuckDuckGo HTML version for easier scraping and privacy
    final url = Uri.parse("https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}");

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url.toString())),
      onLoadStop: (controller, url) async {
        print("[FORAGER] Page loaded: $url");
        
        // 2. Scrape Content
        // We get the first snippet result
        final String? snippet = await controller.evaluateJavascript(source: """
          (function() {
            var el = document.querySelector('.result__snippet');
            return el ? el.innerText : null;
          })();
        """);

        final String? sourceUrl = await controller.evaluateJavascript(source: "window.location.href");

        // 3. Verify
        if (snippet != null && snippet.isNotEmpty) {
           print("[FORAGER] Found snippet: $snippet");
           
           // Run through the Epistemological Firewall
           TruthClass verdict = VerificationEngine.verify(snippet, sourceUrl ?? "unknown");
           
           if (verdict != TruthClass.garbage) {
             if (!_searchCompleter!.isCompleted) _searchCompleter!.complete(snippet);
           } else {
             print("[FORAGER] Snippet rejected by Verification Layer.");
             if (!_searchCompleter!.isCompleted) _searchCompleter!.complete(null);
           }
        } else {
           if (!_searchCompleter!.isCompleted) _searchCompleter!.complete(null);
        }
        
        // Clean up
        // _headlessWebView?.dispose(); // Keep it alive or dispose? Better dispose to save RAM.
      },
      onConsoleMessage: (controller, consoleMessage) {
        print("[BROWSER CONSOLE] ${consoleMessage.message}");
      },
    );

    // Run the invisible browser
    await _headlessWebView?.run();
    
    // Timeout safety
    return _searchCompleter!.future.timeout(const Duration(seconds: 10), onTimeout: () => null).whenComplete(() {
      _headlessWebView?.dispose();
    });
  }
}
