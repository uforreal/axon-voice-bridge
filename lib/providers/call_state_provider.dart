import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// CLOUD SERVER
const String SERVER_URL = 'wss://samantha-cloud-core.onrender.com';

enum CallStatus { idle, connecting, live, muted, listening, speaking }

class CallStateProvider extends ChangeNotifier {
  CallStatus _status = CallStatus.idle;
  bool _isExpanded = false;
  int _currentImageIndex = 0;
  DateTime? _callStartTime;
  bool _isMuted = false;
  
  Timer? _imageTimer;
  Timer? _keepAliveTimer;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  WebSocketChannel? _channel;
  
  bool _speechEnabled = false;
  bool _isInitialized = false;
  String _lastWords = '';

  CallStateProvider() {
    _initializeAll();
    _startImageRotation();
  }

  Future<void> _initializeAll() async {
    try {
      // Initialize TTS first
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      
      // iOS specific: Configure audio session for both input and output
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );

      print("[INIT] TTS configured");

      // Initialize Speech Recognition
      _speechEnabled = await _speech.initialize(
        onError: (e) {
          print('[SPEECH ERROR] ${e.errorMsg}');
          // Try restarting on certain errors
          if (_isExpanded && !_isMuted) {
            Future.delayed(const Duration(seconds: 1), _startListening);
          }
        },
        onStatus: (status) {
          print('[SPEECH STATUS] $status');
          if (status == "notListening" && _isExpanded && !_isMuted && _status != CallStatus.speaking) {
            // Auto-restart listening loop
            Future.delayed(const Duration(milliseconds: 300), _startListening);
          }
        },
      );

      _isInitialized = true;
      print("[INIT] Speech enabled: $_speechEnabled");
      notifyListeners();
      
    } catch (e) {
      print("[INIT ERROR] $e");
    }
  }

  void _startImageRotation() {
    _imageTimer?.cancel();
    _imageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isExpanded) {
        _currentImageIndex = (_currentImageIndex + 1) % 3;
        notifyListeners();
      }
    });
  }

  CallStatus get status => _status;
  bool get isExpanded => _isExpanded;
  int get currentImageIndex => _currentImageIndex;
  bool get isMuted => _isMuted;
  
  String get callDuration {
    if (_callStartTime == null) return "00:00";
    final duration = DateTime.now().difference(_callStartTime!);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void expand() {
    if (!_isInitialized) {
      print("[EXPAND] Not initialized yet, retrying...");
      Future.delayed(const Duration(milliseconds: 500), expand);
      return;
    }
    
    _isExpanded = true;
    _status = CallStatus.connecting;
    _callStartTime = DateTime.now();
    _imageTimer?.cancel();
    notifyListeners();
    
    _connectToSamantha();
  }
  
  void _connectToSamantha() async {
    try {
      print("[WS] Connecting to $SERVER_URL...");
      _channel = WebSocketChannel.connect(Uri.parse(SERVER_URL));
      
      // Start keep-alive pings
      _keepAliveTimer?.cancel();
      _keepAliveTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (_channel != null) {
          _channel!.sink.add(json.encode({"type": "ping"}));
          print("[WS] Ping sent");
        }
      });
      
      _channel!.stream.listen(
        (message) {
          print("[WS] Received: $message");
          _handleServerMessage(message);
        },
        onError: (error) {
          print("[WS ERROR] $error");
          _status = CallStatus.idle;
          notifyListeners();
        },
        onDone: () {
          print("[WS] Connection closed");
          _keepAliveTimer?.cancel();
          if (_isExpanded) collapse();
        }
      );
      
      _status = CallStatus.live;
      notifyListeners();
      
      // Wait a moment for connection to stabilize, then start listening
      await Future.delayed(const Duration(milliseconds: 500));
      _startListening();
      
    } catch (e) {
      print("[WS CONNECT ERROR] $e");
      _status = CallStatus.idle;
      notifyListeners();
    }
  }

  void _handleServerMessage(String message) {
    try {
      final data = json.decode(message);
      if (data['type'] == 'samantha_response') {
        String responseText = data['raw_response'] ?? data['marked_script'] ?? '';
        if (responseText.isNotEmpty) {
          _speak(responseText);
        }
      }
    } catch (e) {
      print("[PARSE ERROR] $e");
    }
  }

  Future<void> _speak(String text) async {
    print("[TTS] Speaking: $text");
    _status = CallStatus.speaking;
    notifyListeners();
    
    // Stop listening while speaking
    await _speech.stop();
    
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
    
    _status = CallStatus.live;
    notifyListeners();
    
    // Resume listening
    await Future.delayed(const Duration(milliseconds: 200));
    _startListening();
  }

  void _startListening() async {
    if (_isMuted || !_speechEnabled || !_isExpanded) {
      print("[LISTEN] Skipped - muted:$_isMuted enabled:$_speechEnabled expanded:$_isExpanded");
      return;
    }
    
    if (_speech.isListening) {
      print("[LISTEN] Already listening");
      return;
    }

    try {
      _status = CallStatus.listening;
      notifyListeners();
      
      print("[LISTEN] Starting...");
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: "en_US",
        cancelOnError: false,
        partialResults: true,
        onSoundLevelChange: (level) {
          // Could visualize
        },
      );
    } catch (e) {
      print("[LISTEN ERROR] $e");
      _status = CallStatus.live;
      notifyListeners();
    }
  }

  void _onSpeechResult(result) {
    _lastWords = result.recognizedWords;
    print("[SPEECH] Heard: $_lastWords (final: ${result.finalResult})");
    
    if (result.finalResult && _lastWords.isNotEmpty) {
      print("[SPEECH] Sending to server: $_lastWords");
      _sendVoiceInput(_lastWords);
      _lastWords = "";
    }
  }

  void _sendVoiceInput(String text) {
    if (_channel != null && text.isNotEmpty) {
      final payload = json.encode({
        "type": "voice_input",
        "content": text
      });
      print("[WS] Sending: $payload");
      _channel!.sink.add(payload);
    }
  }

  void collapse() {
    _isExpanded = false;
    _status = CallStatus.idle;
    _callStartTime = null;
    _isMuted = false;
    _keepAliveTimer?.cancel();
    _tts.stop();
    _speech.stop();
    _channel?.sink.close();
    _startImageRotation();
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _status = _isMuted ? CallStatus.muted : CallStatus.live;
    if (_isMuted) {
      _tts.stop();
      _speech.stop();
    } else {
      _startListening();
    }
    notifyListeners();
  }

  void nextImage() {
    _currentImageIndex = (_currentImageIndex + 1) % 3;
    notifyListeners();
  }

  void setImageIndex(int index) {
    _currentImageIndex = index;
    notifyListeners();
  }
}
