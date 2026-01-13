import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import TTS
import '../utils/thalamus_engine.dart'; // Import Thalamus

// CLOUD SERVER (FastAPI Audio Stream)
const String SERVER_URL = 'wss://samantha-cloud-core.onrender.com/ws';

enum CallStatus { idle, connecting, live, muted, listening, speaking }

class CallStateProvider extends ChangeNotifier {
  CallStatus _status = CallStatus.idle;
  bool _isExpanded = false;
  int _currentImageIndex = 0;
  DateTime? _callStartTime;
  bool _isMuted = false;
  
  Timer? _imageTimer;
  Timer? _keepAliveTimer;
  
  // Audio Input/Output
  final SpeechToText _speech = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts(); // Local TTS
  WebSocketChannel? _channel;
  
  // Audio Buffer for Streaming
  bool _speechEnabled = false;
  bool _isInitialized = false;

  CallStateProvider() {
    _initializeAll();
    _startImageRotation();
  }

  Future<void> _initializeAll() async {
    try {
      // AudioPlayer works with default settings on iOS
      await ThalamusEngine.loadLibrary(); 
      await _flutterTts.setLanguage("en-US");
      _speechEnabled = await _speech.initialize(
        onError: (e) {
          print('[SPEECH ERROR] ${e.errorMsg}');
          if (_isExpanded && !_isMuted) Future.delayed(const Duration(seconds: 1), _startListening);
        },
        onStatus: (status) {
          print('[SPEECH STATUS] $status');
          if (status == "notListening" && _isExpanded && !_isMuted && _status != CallStatus.speaking) {
             Future.delayed(const Duration(milliseconds: 300), _startListening);
          }
        },
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print("[INIT ERROR] $e");
    }
  }

  void expand() {
    if (!_isInitialized) {
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
      
      // Ping Loop
      _keepAliveTimer?.cancel();
      _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
         _channel?.sink.add(json.encode({"type": "ping"}));
      });
      
      _channel!.stream.listen(
        (message) {
          if (message is String) {
            _handleTextMessage(message);
          } else if (message is List<int>) {
            print("[AUDIO] Received chunk: ${message.length} bytes");
            _handleAudioChunk(Uint8List.fromList(message));
          }
        },
        onError: (e) => print("[WS ERROR] $e"),
        onDone: () => shutdown(),
      );
      
      _status = CallStatus.live;
      notifyListeners();
      _startListening();
      
    } catch (e) {
      print("[WS CONNECT ERROR] $e");
      shutdown(); // Ensure we clean up if connection fails
    }
  }

  void _handleTextMessage(String message) {
    try {
      final data = json.decode(message);
      if (data['type'] == 'status') {
         if (data['mode'] == 'speaking') {
           _status = CallStatus.speaking;
           _speech.stop();
           notifyListeners();
         } else if (data['mode'] == 'listening') {
           _status = CallStatus.live;
           _startListening();
           notifyListeners();
         }
      }
    } catch (e) {
      print("[JSON ERROR] $e");
    }
  }

  void _handleAudioChunk(Uint8List chunk) async {
    // Play the audio chunk immediately using Source.bytes
    // Note: In a production stream, we would feed a StreamSource, 
    // but BytesSource is sufficient for proving the Jenny Voice concept.
    try {
      await _audioPlayer.play(BytesSource(chunk));
    } catch (e) {
      print("[PLAYBACK ERROR] $e");
    }
  }

  // Debug Logs
  String _debugLog = "Thalamus Initialized";
  String get debugLog => _debugLog;
  
  List<double> _vibeBuffer = [];
  
  void _log(String msg) {
    _debugLog = msg;
    notifyListeners();
  }

  void _startListening() async {
    if (_isMuted || !_speechEnabled || !_isExpanded || _status == CallStatus.speaking) return;
    if (_speech.isListening) return;

    try {
      _status = CallStatus.listening;
      _vibeBuffer.clear(); // Reset for new sentence
      _log("Listening... (Mic Active)");
      notifyListeners();
      
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
             print("[SENDING] ${result.recognizedWords}");
             
             // Analyze Vibe Buffer
             double avgEnergy = 0.5;
             if (_vibeBuffer.isNotEmpty) {
               avgEnergy = _vibeBuffer.reduce((a, b) => a + b) / _vibeBuffer.length;
               // Scale to 0.0 - 1.0 (Approximate mapping from STT db levels)
               avgEnergy = (avgEnergy + 2) / 10; 
               if (avgEnergy > 1.0) avgEnergy = 1.0;
               if (avgEnergy < 0.0) avgEnergy = 0.0;
             }
             
             _log("Heard: '${result.recognizedWords}' | Energy: ${avgEnergy.toStringAsFixed(2)}");

             _sendVoiceInput(result.recognizedWords, {
               "energy": avgEnergy,
               "density": _vibeBuffer.length / 100, 
             });
          }
        },
        listenFor: const Duration(seconds: 30),
        localeId: "en_US",
        onSoundLevelChange: (level) {
          _vibeBuffer.add(level);
        },
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      print("[LISTEN ERROR] $e");
      _log("Listen Error: $e");
    }
  }

  void _sendVoiceInput(String text, Map<String, dynamic> vibe) async {
    // STOP LISTENING IMMEDIATELY to clear orange dot
    await _speech.stop();
    _status = CallStatus.speaking;
    notifyListeners();

    // 1. Calculate Response Locally (The "Math")
    DateTime start = DateTime.now();
    String responseText = ThalamusEngine.process(text, vibe);
    int latency = DateTime.now().difference(start).inMilliseconds;
    
    _log("Math: ${latency}ms | Resp: '$responseText'");
    print("[THALAMUS RESPONSE] $responseText");

    // 2. Speak it locally (The "Voice")
    await _flutterTts.speak(responseText);
    
    // 3. Wait for speech to finish
    _flutterTts.setCompletionHandler(() {
      _status = CallStatus.live;
      _log("Waiting for user...");
      notifyListeners();
      
      // Auto-listen again
      Future.delayed(const Duration(milliseconds: 500), _startListening);
    });
  }

  // Helpers & Getters
  CallStatus get status => _status;
  bool get isExpanded => _isExpanded;
  int get currentImageIndex => _currentImageIndex;
  bool get isMuted => _isMuted;
  String get callDuration => "00:00"; // Placeholder for now

  void _startImageRotation() { 
     _imageTimer?.cancel();
     _imageTimer = Timer.periodic(const Duration(seconds: 5), (_) {
       if (!_isExpanded) {
         _currentImageIndex = (_currentImageIndex + 1) % 3; 
         notifyListeners();
       }
     });
  }

  void toggleMute() { 
    _isMuted = !_isMuted; 
    notifyListeners(); 
  }
  
  void collapse() => shutdown();
  void nextImage() => _currentImageIndex = (_currentImageIndex + 1) % 3;
  void setImageIndex(int i) => _currentImageIndex = i;
}
