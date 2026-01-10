import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// CONFIGURATION
const String SERVER_URL = 'wss://samantha-cloud-core.onrender.com';

enum CallStatus { idle, connecting, live, muted, listening, speaking }

class CallStateProvider extends ChangeNotifier {
  CallStatus _status = CallStatus.idle;
  bool _isExpanded = false;
  int _currentImageIndex = 0;
  DateTime? _callStartTime;
  bool _isMuted = false;
  
  Timer? _imageTimer;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  WebSocketChannel? _channel;
  
  // Voice Input State
  bool _speechEnabled = false;
  String _lastWords = '';

  CallStateProvider() {
    _initTts();
    _initSpeech();
    _startImageRotation();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    // Configure voice
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (e) => print('Speech Error: $e'),
      onStatus: (s) {
        print('Speech Status: $s');
        // RESTART LOGIC: If we stopped listening but shouldn't have...
        if (s == "notListening") {
          bool shouldBeListening = 
              _isExpanded && 
              !_isMuted && 
              _status != CallStatus.speaking &&
              _status != CallStatus.idle;
              
          if (shouldBeListening) {
            print("Restarting listener loop...");
            // Small delay to prevent tight loops
            Future.delayed(const Duration(milliseconds: 100), () {
              if (shouldBeListening) _startListening();
            });
          }
        }
      },
    );
    notifyListeners();
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
    _isExpanded = true;
    _status = CallStatus.connecting;
    _callStartTime = DateTime.now();
    _imageTimer?.cancel();
    notifyListeners();
    
    // Connect to Backend
    _connectToSamantha();
  }
  
  void _connectToSamantha() async {
    try {
      print("Connecting to $SERVER_URL...");
      _channel = WebSocketChannel.connect(Uri.parse(SERVER_URL));
      
      // Listen for messages
      _channel!.stream.listen(
        (message) {
          print("Received: $message");
          _handleServerMessage(message);
        },
        onError: (error) {
          print("WebSocket Error: $error");
          _status = CallStatus.idle;
          notifyListeners();
        },
        onDone: () {
          print("WebSocket Closed");
          if (_isExpanded) collapse();
        }
      );
      
      // Signal we are connected
      _status = CallStatus.live;
      notifyListeners();
      
      // Initial Greeting
      _startListening();
      
    } catch (e) {
      print("Connection Failed: $e");
    }
  }

  void _handleServerMessage(String message) {
    try {
      final data = json.decode(message);
      if (data['type'] == 'samantha_response') {
        String responseText = data['raw_response']; 
        _speak(responseText);
      }
    } catch (e) {
      print("Error parsing message: $e");
    }
  }

  Future<void> _speak(String text) async {
    _status = CallStatus.speaking;
    notifyListeners();
    
    // Stop listening while speaking to avoid self-loop
    await _speech.stop();
    
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
    
    _status = CallStatus.live;
    notifyListeners();
    
    // Resume listening after speaking
    _startListening();
  }

  void _startListening() async {
    if (_isMuted || !_speechEnabled) return;
    
    if (!_speech.isListening) {
      _status = CallStatus.listening;
      notifyListeners();
      
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: "en_US",
        onSoundLevelChange: (level) {
          // Could visualize audio level here
        },
      );
    }
  }

  void _onSpeechResult(result) {
    _lastWords = result.recognizedWords;
    
    if (result.finalResult) {
       print("Sending: $_lastWords");
       _sendVoiceInput(_lastWords);
       _lastWords = "";
       // Note: listening usually stops automatically on final result, 
       // triggering onStatus("notListening") -> which restarts the loop
    }
  }

  void _sendVoiceInput(String text) {
    if (_channel != null && text.isNotEmpty) {
      _channel!.sink.add(json.encode({
        "type": "voice_input",
        "content": text
      }));
    }
  }

  void collapse() {
    _isExpanded = false;
    _status = CallStatus.idle;
    _callStartTime = null;
    _isMuted = false;
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
