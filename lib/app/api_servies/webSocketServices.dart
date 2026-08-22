import 'dart:convert';

import 'package:HRlynx/app/api_servies/api_Constant.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Stream? _broadcastStream;
  String? _currentSessionId;
  int? personaId;

  final RxBool _isConnected = false.obs;

  // Token limit survives ChatController rebuilds.
  bool _isLimitReached = false;

  bool get isConnected => _isConnected.value;
  bool get isLimitReached => _isLimitReached;

  // Reset limit only for a new session.
  void resetForNewSession() {
    _isLimitReached = false;
    print('WS: Limit reset for new session');
  }

  Future<void> connect(String sessionId, String token, {int? personaId}) async {
    this.personaId = personaId;


    await disconnect();

    try {
      final uri = Uri.parse(
        "${ApiConstants.wsBaseUrl}/ws/chat/$sessionId/?token=$token",
      );
      print('Connecting to WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);
      _currentSessionId = sessionId;

      _broadcastStream = _channel!.stream.asBroadcastStream();

      _broadcastStream!.listen(
            (event) {
          print('Incoming: $event');

          try {
            final data = jsonDecode(event);

            if (data['type'] == 'connection') {
              _isConnected.value = true;
              print('WebSocket Connection Confirmed');
            }

            if (data['type'] == 'limit_reached') {
              _isLimitReached = true;
              print('WS: Limit reached flag set');
            }

            if (data['limit_info'] != null &&
                data['limit_info']['limit_reached'] == true) {
              _isLimitReached = true;
              print('WS: Limit reached via message limit_info');
            }

          } catch (e) {
          }
        },
        onError: (err) {
          print('WebSocket Error: $err');
          _isConnected.value = false;
        },
        onDone: () {
          print('WebSocket stream closed');
          _isConnected.value = false;
        },
        cancelOnError: false,
      );

      await Future.delayed(const Duration(milliseconds: 1000));

      if (!_isConnected.value) {
        _isConnected.value = true;
        print('WebSocket Connected (assumed)');
      }

    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected.value = false;
      rethrow;
    }
  }

  void sendMessage(String msg) {
    if (_isLimitReached) {
      print('WS: Message blocked — limit reached');
      return;
    }

    if (_channel != null && _isConnected.value && _currentSessionId != null) {
      try {
        final messageData = {
          "type": "message",
          "message": msg,
          "session_id": int.tryParse(_currentSessionId!) ?? _currentSessionId
        };

        final jsonMessage = jsonEncode(messageData);
        _channel!.sink.add(jsonMessage);
        print('Outgoing JSON: $jsonMessage');
      } catch (e) {
        print('Error sending message: $e');
        _isConnected.value = false;
      }
    } else {
      print('Cannot send message - WebSocket not connected');
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
      print('WebSocket disconnected');
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  Stream get stream {
    if (_broadcastStream != null) {
      return _broadcastStream!;
    }
    return const Stream.empty();
  }
}
