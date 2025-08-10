import 'dart:convert';
import 'package:hr/app/api_servies/api_Constant.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Stream? _broadcastStream;
  String? _currentSessionId; // Store session ID for sending messages
  int? personaId;

  final RxBool _isConnected = false.obs;

  bool get isConnected => _isConnected.value;

  Future<void> connect(String sessionId, String token, {int? personaId}) async {

    this.personaId = personaId;
    // First disconnect any existing connection
    await disconnect();

    try {
      final uri = Uri.parse(
        "${ApiConstants.wsBaseUrl}/ws/chat/$sessionId/?token=$token",
      );
      print('🔌 Connecting to WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);
      _currentSessionId = sessionId; // Store session ID

      // Create broadcast stream BEFORE setting connected status
      _broadcastStream = _channel!.stream.asBroadcastStream();

      // Set up stream listeners
      _broadcastStream!.listen(
            (event) {
          print('📥 Incoming: $event');

          // Try to parse the event to check if it's a connection confirmation
          try {
            final data = jsonDecode(event);
            if (data['type'] == 'connection') {
              _isConnected.value = true;
              print('✅ WebSocket Connection Confirmed');
            }
          } catch (e) {
            // Not JSON or different format, that's okay
          }
        },
        onError: (err) {
          print('❌ WebSocket Error: $err');
          _isConnected.value = false;
        },
        onDone: () {
          print('✅ WebSocket stream closed');
          _isConnected.value = false;
        },
        cancelOnError: false, // Don't cancel on error, keep trying
      );

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 1000));

      // If we haven't received a connection confirmation, assume connected
      if (!_isConnected.value) {
        _isConnected.value = true;
        print('✅ WebSocket Connected (assumed)');
      }

    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _isConnected.value = false;
      rethrow;
    }
  }

  void sendMessage(String msg) {
    if (_channel != null && _isConnected.value && _currentSessionId != null) {
      try {
        // Create the correct JSON format that your server expects
        final messageData = {
          "type": "message",
          "message": msg,
          "session_id": int.tryParse(_currentSessionId!) ?? _currentSessionId
        };

        final jsonMessage = jsonEncode(messageData);
        _channel!.sink.add(jsonMessage);
        print('📤 Outgoing JSON: $jsonMessage');
      } catch (e) {
        print('❌ Error sending message: $e');
        _isConnected.value = false;
      }
    } else {
      print('❌ Cannot send message - WebSocket not connected');
      print('Channel: ${_channel != null ? "exists" : "null"}');
      print('Connected: ${_isConnected.value}');
      print('Session ID: $_currentSessionId');
    }
  }

  Future<void> disconnect() async {
    try {
      _isConnected.value = false;

      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }

      _broadcastStream = null;
      _currentSessionId = null;

      print('✅ WebSocket disconnected');
    } catch (e) {
      print('❌ Error disconnecting WebSocket: $e');
    }
  }

  // This is the key fix - return the broadcast stream properly
  Stream get stream {
    if (_broadcastStream != null) {
      return _broadcastStream!;
    }
    return const Stream.empty();
  }
}