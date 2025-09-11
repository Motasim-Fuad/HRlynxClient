import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart' show ApiConstants;
import 'package:hr/app/api_servies/token.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

class VoiceService extends GetxController {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // Observable variables
  var isRecording = false.obs;
  var isProcessing = false.obs;
  var isPlaying = false.obs;
  var recordingDuration = 0.obs;
  var playbackPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var currentPlayingUrl = ''.obs;
  var playbackProgress = 0.0.obs;

  String? _recordingPath;
  Timer? _recordingTimer;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playerPositionSubscription;
  StreamSubscription? _playerDurationSubscription;
  StreamSubscription? _playerCompleteSubscription;

  // Cache for downloaded audio files
  final Map<String, String> _audioCache = {};

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayerListeners();
    _configureAudioPlayer();
  }

  Future<void> _configureAudioPlayer() async {
    try {
      await _player.setVolume(1.0);
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      print('🎵 Audio player configured successfully');
    } catch (e) {
      print('⚠️ Error configuring audio player: $e');
    }
  }

  void _setupAudioPlayerListeners() {
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      print('🎵 Audio playback completed');
      _resetPlaybackState();
    });

    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      print('🎵 Player state changed: $state');

      switch (state) {
        case PlayerState.completed:
        case PlayerState.stopped:
          _resetPlaybackState();
          break;
        case PlayerState.playing:
          isPlaying.value = true;
          break;
        case PlayerState.paused:
          isPlaying.value = false;
          break;
        default:
          break;
      }
    });

    _playerPositionSubscription = _player.onPositionChanged.listen((position) {
      playbackPosition.value = position;

      if (totalDuration.value.inMilliseconds > 0) {
        playbackProgress.value = position.inMilliseconds / totalDuration.value.inMilliseconds;
      }

      // Auto-stop when reaching end
      if (totalDuration.value.inMilliseconds > 0 &&
          position.inMilliseconds >= totalDuration.value.inMilliseconds - 200) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (isPlaying.value) {
            _resetPlaybackState();
          }
        });
      }
    });

    _playerDurationSubscription = _player.onDurationChanged.listen((duration) {
      totalDuration.value = duration;
      print('🎵 Audio duration: ${duration.inSeconds} seconds');
    });
  }

  void _resetPlaybackState() {
    print('🎵 Resetting playback state');
    isPlaying.value = false;
    currentPlayingUrl.value = '';
    playbackPosition.value = Duration.zero;
    playbackProgress.value = 0.0;

    // Keep total duration for a moment to show completion
    Future.delayed(Duration(milliseconds: 500), () {
      if (!isPlaying.value) {
        totalDuration.value = Duration.zero;
      }
    });
  }

  // Main method for playing voice messages (Messenger-style)
  Future<void> playVoiceMessage(String voiceUrl) async {
    try {
      print('🎵 Playing voice message: $voiceUrl');

      // Stop any currently playing audio first
      if (isPlaying.value) {
        await stopPlayback();
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Set current playing URL
      currentPlayingUrl.value = voiceUrl;

      // Use cached file if available, otherwise download
      String? localPath = _audioCache[voiceUrl];

      if (localPath == null || !File(localPath).existsSync()) {
        localPath = await _downloadAudioFile(voiceUrl);
        if (localPath != null) {
          _audioCache[voiceUrl] = localPath;
        }
      }

      if (localPath != null) {
        await _playFromLocalFile(localPath);
      } else {
        throw Exception('Failed to download audio file');
      }

    } catch (e) {
      print('❌ Error playing voice message: $e');
      _handlePlaybackError();
    }
  }

  Future<void> pauseVoiceMessage() async {
    try {
      print('🎵 Pausing playback');
      await _player.pause();
    } catch (e) {
      print('❌ Error pausing playback: $e');
      _handlePlaybackError();
    }
  }

  Future<void> resumeVoiceMessage() async {
    try {
      print('🎵 Resuming playback');
      await _player.resume();
    } catch (e) {
      print('❌ Error resuming playback: $e');
      _handlePlaybackError();
    }
  }

  Future<void> stopPlayback() async {
    try {
      print('🎵 Stopping playback');
      await _player.stop();
      _resetPlaybackState();
    } catch (e) {
      print('❌ Error stopping playback: $e');
      _resetPlaybackState();
    }
  }

  Future<String?> _downloadAudioFile(String voiceUrl) async {
    try {
      String downloadUrl = voiceUrl;
      if (!voiceUrl.startsWith('http')) {
        downloadUrl = '${ApiConstants.baseUrl}$voiceUrl';
      }

      print('🎵 Downloading: $downloadUrl');

      final token = await TokenStorage.getLoginAccessToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final directory = await getTemporaryDirectory();
        final fileName = 'voice_${voiceUrl.hashCode.abs()}.wav';
        final localPath = '${directory.path}/$fileName';

        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        print('🎵 Downloaded to: $localPath (${response.bodyBytes.length} bytes)');
        return localPath;
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Download error: $e');
      return null;
    }
  }

  Future<void> _playFromLocalFile(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists() || await file.length() == 0) {
        print("Local file does not exist or is empty");
        throw Exception('Local file does not exist or is empty');

      }

      print('🎵 Playing from: $localPath');
      print('🎵 solution');
      await _player.play(DeviceFileSource(localPath));
      // here is my error
      print('@@@@@@@@@ my voice local Playing from: $localPath');
    } catch (e) {
      print('❌ Play from local file error: $e');
      throw e;
    }
  }

  void _handlePlaybackError() {
    print('🎵 Handling playback error');
    _resetPlaybackState();

    Get.snackbar(
      "Playback Error",
      "Unable to play voice message",
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      icon: Icon(Icons.error_outline, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  bool isPlayingUrl(String url) {
    return isPlaying.value && currentPlayingUrl.value == url;
  }



  Future<bool> _checkPermission() async {
    try {
      print("🎤 Checking native iOS permission only...");

      // শুধুমাত্র AudioRecorder এর নিজের permission check করবো
      // কারণ iOS এ এটাই সবচেয়ে reliable
      bool hasPermission = await _recorder.hasPermission();
      print("🎤 Native recorder permission: $hasPermission");

      if (hasPermission) {
        print("✅ Native permission granted, ready to record");
        return true;
      } else {
        print("❌ Native permission denied");

        // যদি permission না থাকে, user কে manual settings এ যেতে বলবো
        _showManualPermissionDialog();
        return false;
      }

    } catch (e) {
      print("🎤 Error checking permission: $e");
      return false;
    }
  }

  void _showManualPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Microphone Permission Needed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please enable microphone access manually:'),
            SizedBox(height: 12),
            Text('1. Go to iPhone Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('2. Find "HRlynx" app'),
            Text('3. Turn ON Microphone'),
            Text('4. Come back to app'),
            SizedBox(height: 12),
            Text('Then try recording again.', style: TextStyle(color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // iOS Settings এ নিয়ে যাবে
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }


  Future<bool> startRecording() async {
    try {
      print("🎤 Starting recording (iOS native only)...");

      // শুধু native permission check
      bool hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        print("🎤 No native permission");

        Get.snackbar(
          "Permission Required",
          "Please enable microphone in Settings → HRlynx → Microphone",
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );

        return false;
      }

      // Recording setup
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/voice_message_$timestamp.wav';

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      final recordingPath = _recordingPath;
      if (recordingPath == null) {
        throw Exception("Recording path is null");
      }

      print("🎤 Starting recording to: $recordingPath");

      // Start recording
      await _recorder.start(config, path: recordingPath);

      // Update state
      isRecording.value = true;
      recordingDuration.value = 0;

      // Duration timer
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        recordingDuration.value++;
      });

      print("✅ Recording started successfully");

      Get.snackbar(
        "Recording Started",
        "Recording voice message...",
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
        icon: Icon(Icons.mic, color: Colors.white),
      );

      return true;

    } catch (e) {
      print('❌ Recording error: $e');

      // Reset state
      isRecording.value = false;
      recordingDuration.value = 0;
      _recordingTimer?.cancel();

      // Show error
      Get.snackbar(
        "Recording Failed",
        "Could not start recording. Check microphone permission.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      return false;
    }
  }



  Future<Map<String, dynamic>?> stopRecordingAndSendToChat(String sessionId) async {
    try {
      if (!isRecording.value) return null;

      await _recorder.stop();
      _recordingTimer?.cancel();
      isRecording.value = false;
      isProcessing.value = true;

      final recordingPath = _recordingPath;
      if (recordingPath == null || !File(recordingPath).existsSync()) {
        Get.snackbar("Error", "Recording file not found");
        isProcessing.value = false;
        return null;
      }

      final response = await _sendVoiceToBackend(recordingPath, sessionId);
      isProcessing.value = false;
      return response;

    } catch (e) {
      print('❌ Error stopping recording: $e');
      isProcessing.value = false;
      return null;
    }
  }

  Future<Map<String, dynamic>?> _sendVoiceToBackend(String filePath, String sessionId) async {
    try {
      final token = await TokenStorage.getLoginAccessToken();
      final uri = Uri.parse("${ApiConstants.baseUrl}/api/chat/voice-to-text/");

      if (token == null) {
        Get.snackbar("Error", "Authentication token not found");
        return null;
      }

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['session_id'] = sessionId;

      final audioFile = await http.MultipartFile.fromPath(
        'voice_file',
        filePath,
        filename: 'voice_message.wav',
      );
      request.files.add(audioFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse;
        }
      }

      Get.snackbar("Error", "Failed to send voice message");
      return null;

    } catch (e) {
      print('❌ Error sending voice to backend: $e');
      Get.snackbar("Error", "Failed to process voice");
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (isRecording.value) {
        await _recorder.stop();
        _recordingTimer?.cancel();
        isRecording.value = false;
        recordingDuration.value = 0;

        final recordingPath = _recordingPath;
        if (recordingPath != null && File(recordingPath).existsSync()) {
          await File(recordingPath).delete();
        }
      }
    } catch (e) {
      print('❌ Error canceling recording: $e');
    }
  }

  // Utility methods
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String formatDurationFromDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Clean up cache periodically
  void clearAudioCache() {
    _audioCache.forEach((url, path) {
      final file = File(path);
      if (file.existsSync()) {
        file.delete().catchError((e) => print('⚠️ Cache cleanup error: $e'));
      }
    });
    _audioCache.clear();
  }

  @override
  void onClose() {
    clearAudioCache();

    _playerStateSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _playerDurationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _recordingTimer?.cancel();

    _recorder.dispose();
    _player.dispose();
    super.onClose();
  }
}