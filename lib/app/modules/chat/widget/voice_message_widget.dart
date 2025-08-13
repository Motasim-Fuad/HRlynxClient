import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart';
import 'dart:math' as math;

class VoiceMessageBubble extends StatefulWidget {
  final String? voiceUrl;
  final String? transcript;
  final bool isUser;
  final String timestamp;
  final Duration? audioDuration; // Optional duration from backend

  const VoiceMessageBubble({
    Key? key,
    required this.voiceUrl,
    this.transcript,
    required this.isUser,
    required this.timestamp,
    this.audioDuration,
  }) : super(key: key);

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  bool _isDisposed = false;

  // FIXED: Get VoiceService globally instead of passing it
  VoiceService get voiceService {
    if (Get.isRegistered<VoiceService>()) {
      return Get.find<VoiceService>();
    } else {
      // Fallback: create one if not exists (shouldn't happen but safety)
      return Get.put(VoiceService(), permanent: true);
    }
  }

  // Static wave heights for consistent look (like Messenger)
  List<double> _staticWaveHeights = [];
  List<double> _animatedWaveHeights = [];
  final int _waveCount = 15;

  @override
  void initState() {
    super.initState();
    _initializeWaveHeights();
    _setupAnimations();
    _setupVoiceServiceListener();
  }

  void _setupVoiceServiceListener() {
    ever(voiceService.isPlaying, (isPlaying) {
      if (!_isDisposed) {
        _updateAnimations();
      }
    });

    ever(voiceService.currentPlayingUrl, (currentUrl) {
      if (!_isDisposed) {
        _updateAnimations();
      }
    });
  }

  void _initializeWaveHeights() {
    // Create consistent wave pattern (like Messenger's static waves)
    final random = math.Random(42); // Fixed seed for consistency
    _staticWaveHeights = List.generate(_waveCount, (index) {
      // Create varied but predictable heights
      double baseHeight = 12.0 + (random.nextDouble() * 16.0);

      // Make some waves taller for visual appeal
      if (index == 3 || index == 7 || index == 11) {
        baseHeight += 8.0;
      }

      return baseHeight;
    });

    _animatedWaveHeights = List.from(_staticWaveHeights);
  }

  void _setupAnimations() {
    // Wave animation for playing state
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveAnimationController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for play button
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation.addListener(() {
      if (!_isDisposed) {
        _updateWaveHeights();
      }
    });
  }

  void _updateWaveHeights() {
    if (!mounted) return;

    setState(() {
      for (int i = 0; i < _waveCount; i++) {
        double phase = _waveAnimation.value + (i * 0.4);
        double multiplier = (1 + math.sin(phase)) / 2;

        // More dramatic animation for middle waves
        if (i >= 5 && i <= 9) {
          multiplier = (1 + math.sin(phase * 1.5)) / 2;
        }

        _animatedWaveHeights[i] = _staticWaveHeights[i] * (0.4 + multiplier * 0.8);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _waveAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _updateAnimations() {
    final isThisPlaying = _isCurrentlyPlaying();

    if (isThisPlaying) {
      if (!_waveAnimationController.isAnimating) {
        _waveAnimationController.repeat();
      }
      if (!_pulseAnimationController.isAnimating) {
        _pulseAnimationController.repeat(reverse: true);
      }
    } else {
      _waveAnimationController.stop();
      _pulseAnimationController.stop();
      _pulseAnimationController.reset();

      // Reset to static heights
      setState(() {
        _animatedWaveHeights = List.from(_staticWaveHeights);
      });
    }
  }

  bool _isCurrentlyPlaying() {
    return widget.voiceUrl != null &&
        widget.voiceUrl!.isNotEmpty &&
        voiceService.isPlaying.value &&
        voiceService.currentPlayingUrl.value == widget.voiceUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isUser
            ? Color(0xFF007AFF) // iOS blue
            : Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(widget.isUser ? 18 : 4),
          bottomRight: Radius.circular(widget.isUser ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button with Messenger-style design
          Obx(() {
            final isThisPlaying = _isCurrentlyPlaying();
            final isLoading = voiceService.isProcessing.value;

            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isThisPlaying ? _pulseAnimation.value : 1.0,
                  child: GestureDetector(
                    onTap: _handlePlayPause,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.isUser
                            ? Colors.white.withOpacity(0.2)
                            : Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isUser ? Colors.white : Colors.white,
                            ),
                          ),
                        ),
                      )
                          : Icon(
                        isThisPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.isUser ? Colors.white : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          SizedBox(width: 8),

          // Waveform visualization
          Expanded(
            child: Container(
              height: 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_waveCount, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 0.5),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 100),
                        height: _animatedWaveHeights[index],
                        decoration: BoxDecoration(
                          color: widget.isUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          SizedBox(width: 8),

          // Duration display
          Obx(() {
            final isThisPlaying = _isCurrentlyPlaying();
            final duration = voiceService.totalDuration.value;
            final position = voiceService.playbackPosition.value;

            String timeText = "0:15"; // Default

            if (widget.audioDuration != null) {
              // Use provided duration
              if (isThisPlaying && position.inSeconds > 0) {
                final remaining = widget.audioDuration! - position;
                timeText = _formatDuration(remaining);
              } else {
                timeText = _formatDuration(widget.audioDuration!);
              }
            } else if (duration.inSeconds > 0) {
              // Use detected duration
              if (isThisPlaying) {
                final remaining = duration - position;
                timeText = _formatDuration(remaining);
              } else {
                timeText = _formatDuration(duration);
              }
            }

            return Text(
              timeText,
              style: TextStyle(
                fontSize: 12,
                color: widget.isUser
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ],
      ),
    );
  }

  void _handlePlayPause() async {
    if (widget.voiceUrl == null || widget.voiceUrl!.isEmpty) {
      _showErrorSnackbar("Voice file not available");
      print("Voice file not available");
      return;
    }

    try {
      final isThisPlaying = _isCurrentlyPlaying();

      if (isThisPlaying) {
        // Pause current audio
        await voiceService.pauseVoiceMessage();
      } else {
        // Play this audio (will stop others automatically)
        await voiceService.playVoiceMessage(widget.voiceUrl!);
      }
    } catch (e) {
      print('❌ Error in play/pause: $e');
      _showErrorSnackbar("Could not play voice message");
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}