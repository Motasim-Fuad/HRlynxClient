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

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayerListeners();
    _configureAudioPlayer();
  }

  void _configureAudioPlayer() async {
    try {
      await _player.setVolume(1.0);
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      print('🎵 Audio player configured successfully');
    } catch (e) {
      print('⚠️ Error configuring audio player: $e');
    }
  }

  void _setupAudioPlayerListeners() {
    // Player completion listener
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      print('🎵 Audio playback completed - resetting state');
      _resetPlaybackState();
    });

    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      print('🎵 Player state changed: $state');

      // Update state immediately based on player state
      switch (state) {
        case PlayerState.completed:
        case PlayerState.stopped:
          print('🎵 Player completed/stopped - resetting state');
          _resetPlaybackState();
          break;
        case PlayerState.playing:
          print('🎵 Player is playing - updating state');
          isPlaying.value = true;
          break;
        case PlayerState.paused:
          print('🎵 Player is paused - updating state');
          isPlaying.value = false;
          break;
        default:
          break;
      }
    });

    _playerPositionSubscription = _player.onPositionChanged.listen((position) {
      playbackPosition.value = position;

      // Update progress percentage
      if (totalDuration.value.inMilliseconds > 0) {
        playbackProgress.value = position.inMilliseconds / totalDuration.value.inMilliseconds;
      }

      // Check if audio has finished playing manually (fallback)
      if (totalDuration.value.inMilliseconds > 0 &&
          position.inMilliseconds >= totalDuration.value.inMilliseconds - 100) {
        print('🎵 Audio reached end - manual completion');
        Future.delayed(Duration(milliseconds: 100), () {
          _resetPlaybackState();
        });
      }
    });

    _playerDurationSubscription = _player.onDurationChanged.listen((duration) {
      totalDuration.value = duration;
      print('🎵 Audio duration: ${duration.inSeconds} seconds');
    });
  }

  // Simplified toggle method with better state management
  Future<void> togglePlayPause(String voiceUrl) async {
    try {
      print('🎵 togglePlayPause called for URL: $voiceUrl');
      print('🎵 Current state - isPlaying: ${isPlaying.value}, currentUrl: ${currentPlayingUrl.value}');

      if (isPlayingUrl(voiceUrl)) {
        // Currently playing this URL - pause it
        print('🎵 Pausing current audio');
        await pauseVoiceMessage();
      } else {
        // Not playing this URL - play it
        print('🎵 Starting to play audio');
        await playVoiceMessage(voiceUrl);
      }
    } catch (e) {
      print('❌ Error toggling play/pause: $e');
      _handlePlaybackError();
    }
  }

  void _resetPlaybackState() {
    print('🎵 Resetting playback state');
    isPlaying.value = false;
    currentPlayingUrl.value = '';
    playbackPosition.value = Duration.zero;
    playbackProgress.value = 0.0;

    // Reset total duration after a delay to show final time briefly
    Future.delayed(Duration(milliseconds: 1000), () {
      if (!isPlaying.value) {
        totalDuration.value = Duration.zero;
      }
    });
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> startRecording() async {
    try {
      if (!await _checkPermission()) {
        Get.snackbar("Permission Denied", "Microphone permission is required");
        return false;
      }

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
      if (recordingPath != null) {
        await _recorder.start(config, path: recordingPath);
        isRecording.value = true;
        recordingDuration.value = 0;

        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          recordingDuration.value++;
        });

        return true;
      } else {
        print('❌ Recording path is null');
        return false;
      }
    } catch (e) {
      print('❌ Error starting recording: $e');
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

      print('🎤 Sending voice file to backend with session_id: $sessionId');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Voice API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse;
        } else {
          Get.snackbar("Error", "Failed to send voice message");
          return null;
        }
      } else {
        Get.snackbar("Error", "Server error: ${response.statusCode}");
        return null;
      }

    } catch (e) {
      print('❌ Error sending voice to backend: $e');
      Get.snackbar("Error", "Failed to process voice: $e");
      return null;
    }
  }

  Future<void> playVoiceMessage(String voiceUrl) async {
    try {
      print('🎵 playVoiceMessage called for: $voiceUrl');

      // If playing different URL, stop it first
      if (isPlaying.value && currentPlayingUrl.value != voiceUrl) {
        print('🎵 Stopping different audio first');
        await stopPlayback();
        await Future.delayed(Duration(milliseconds: 200));
      }

      // Set the currently playing URL immediately
      currentPlayingUrl.value = voiceUrl;

      // Download and play
      await _downloadAndPlay(voiceUrl);

    } catch (e) {
      print('❌ Error playing voice message: $e');
      _handlePlaybackError();
    }
  }

  Future<void> pauseVoiceMessage() async {
    try {
      print('🎵 Pausing playback');
      await _player.pause();
      // State will be updated by the listener
    } catch (e) {
      print('❌ Error pausing playback: $e');
      _handlePlaybackError();
    }
  }

  Future<void> resumeVoiceMessage() async {
    try {
      print('🎵 Resuming playback');
      await _player.resume();
      // State will be updated by the listener
    } catch (e) {
      print('❌ Error resuming playback: $e');
      _handlePlaybackError();
    }
  }

  Future<void> _downloadAndPlay(String voiceUrl) async {
    try {
      print('🎵 Downloading and playing: $voiceUrl');

      String downloadUrl = voiceUrl;
      if (!voiceUrl.startsWith('http')) {
        downloadUrl = '${ApiConstants.baseUrl}$voiceUrl';
      }

      print('🎵 Download URL: $downloadUrl');

      final token = await TokenStorage.getLoginAccessToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Download with timeout
      final response = await http.get(
          Uri.parse(downloadUrl),
          headers: headers
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final fileName = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        final localPath = '${directory.path}/$fileName';

        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        print('🎵 File downloaded to: $localPath, size: ${response.bodyBytes.length} bytes');

        // Verify file exists and has content
        if (await file.exists() && await file.length() > 0) {
          // Stop any current playback
          await _player.stop();
          await Future.delayed(Duration(milliseconds: 100));

          // Play from local file
          await _player.play(DeviceFileSource(localPath));
          print('🎵 Started playing from local file');

          // Clean up file after playing
          Future.delayed(Duration(minutes: 2), () {
            if (file.existsSync()) {
              file.delete().catchError((e) => print('⚠️ Could not delete temp file: $e'));
            }
          });
        } else {
          throw Exception('Downloaded file is empty or does not exist');
        }

      } else {
        throw Exception('Failed to download audio file: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      print('❌ Download and play method failed: $e');
      _handlePlaybackError();
    }
  }

  void _handlePlaybackError() {
    print('🎵 Handling playback error');
    _resetPlaybackState();

    Get.snackbar(
      "Audio Error",
      "Could not play voice message. Please check your internet connection.",
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      icon: Icon(Icons.error_outline, color: Colors.white),
    );
  }

  Future<void> stopPlayback() async {
    try {
      print('🎵 Stopping playback');
      await _player.stop();
      _resetPlaybackState();
    } catch (e) {
      print('❌ Error stopping playback: $e');
    }
  }

  bool isPlayingUrl(String url) {
    final result = isPlaying.value && currentPlayingUrl.value == url;
    print('🎵 isPlayingUrl($url): $result (current: ${currentPlayingUrl.value}, isPlaying: ${isPlaying.value})');
    return result;
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

  @override
  void onClose() {
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