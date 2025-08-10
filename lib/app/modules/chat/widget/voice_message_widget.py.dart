import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart';
import 'dart:math' as math;

class VoiceMessageBubble extends StatefulWidget {
  final String? voiceUrl;
  final String? transcript;
  final bool isUser;
  final String timestamp;
  final VoiceService voiceService;

  const VoiceMessageBubble({
    Key? key,
    required this.voiceUrl,
    this.transcript,
    required this.isUser,
    required this.timestamp,
    required this.voiceService,
  }) : super(key: key);

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _colorAnimationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  late Animation<Color?> _colorAnimation3;
  bool _isDisposed = false;

  // Dynamic wave heights for more realistic animation
  List<double> _waveHeights = [];
  final int _waveCount = 20;

  @override
  void initState() {
    super.initState();
    _initializeWaveHeights();
    _setupAnimations();
    _setupVoiceServiceListener();
  }

  void _setupVoiceServiceListener() {
    // Listen to voice service changes and update animations accordingly
    ever(widget.voiceService.isPlaying, (isPlaying) {
      if (!_isDisposed) {
        final isThisPlaying = widget.voiceUrl != null &&
            widget.voiceUrl!.isNotEmpty &&
            isPlaying &&
            widget.voiceService.currentPlayingUrl.value == widget.voiceUrl;

        _updateAnimations(isThisPlaying);
      }
    });

    ever(widget.voiceService.currentPlayingUrl, (currentUrl) {
      if (!_isDisposed) {
        final isThisPlaying = widget.voiceUrl != null &&
            widget.voiceUrl!.isNotEmpty &&
            widget.voiceService.isPlaying.value &&
            currentUrl == widget.voiceUrl;

        _updateAnimations(isThisPlaying);
      }
    });
  }

  void _initializeWaveHeights() {
    _waveHeights = List.generate(_waveCount, (index) {
      // Create varied heights for more natural wave appearance
      return (math.Random().nextDouble() * 0.8 + 0.2) * 24.0;
    });
  }

  void _setupAnimations() {
    // Main wave animation - faster for more dynamic effect
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    // Color animation for dynamic wave colors
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Multiple color animations for gradient effect
    _colorAnimation1 = ColorTween(
      begin: widget.isUser ? Colors.blue.shade400 : Colors.grey.shade500,
      end: widget.isUser ? Colors.purple.shade400 : Colors.green.shade400,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation2 = ColorTween(
      begin: widget.isUser ? Colors.purple.shade400 : Colors.green.shade400,
      end: widget.isUser ? Colors.pink.shade400 : Colors.teal.shade400,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation3 = ColorTween(
      begin: widget.isUser ? Colors.pink.shade400 : Colors.teal.shade400,
      end: widget.isUser ? Colors.orange.shade400 : Colors.indigo.shade400,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _waveAnimationController.dispose();
    _pulseAnimationController.dispose();
    _colorAnimationController.dispose();
    super.dispose();
  }

  void _updateAnimations(bool isPlaying) {
    if (isPlaying) {
      // Start all animations when playing
      if (!_waveAnimationController.isAnimating) {
        _waveAnimationController.repeat();
      }
      if (!_pulseAnimationController.isAnimating) {
        _pulseAnimationController.repeat(reverse: true);
      }
      if (!_colorAnimationController.isAnimating) {
        _colorAnimationController.repeat(reverse: true);
      }
    } else {
      // Stop all animations when not playing
      _waveAnimationController.stop();
      _waveAnimationController.reset();
      _pulseAnimationController.stop();
      _pulseAnimationController.reset();
      _colorAnimationController.stop();
      _colorAnimationController.reset();
    }
  }

  Color _getWaveColor(int index, bool isPlaying) {
    if (!isPlaying) {
      return widget.isUser
          ? Colors.blue.shade300
          : Colors.grey.shade500;
    }

    // Cycle through different colors based on index
    switch (index % 3) {
      case 0:
        return _colorAnimation1.value ?? Colors.blue.shade400;
      case 1:
        return _colorAnimation2.value ?? Colors.purple.shade400;
      case 2:
        return _colorAnimation3.value ?? Colors.pink.shade400;
      default:
        return _colorAnimation1.value ?? Colors.blue.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isUser ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice player row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Play/Pause button with pulse animation
              Obx(() {
                final isThisPlaying = widget.voiceUrl != null &&
                    widget.voiceUrl!.isNotEmpty &&
                    widget.voiceService.isPlaying.value &&
                    widget.voiceService.currentPlayingUrl.value == widget.voiceUrl;

                print('🎵 Button state - isPlaying: ${widget.voiceService.isPlaying.value}, currentUrl: ${widget.voiceService.currentPlayingUrl.value}, thisUrl: ${widget.voiceUrl}, isThisPlaying: $isThisPlaying');

                return AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isThisPlaying ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: () async {
                          if (widget.voiceUrl != null && widget.voiceUrl!.isNotEmpty) {
                            print('🎵 Button tapped - Current state: isPlaying=${widget.voiceService.isPlaying.value}, currentUrl=${widget.voiceService.currentPlayingUrl.value}');

                            try {
                              if (isThisPlaying) {
                                print('🎵 Pausing current audio');
                                await widget.voiceService.pauseVoiceMessage();
                              } else {
                                print('🎵 Playing new audio: ${widget.voiceUrl}');
                                await widget.voiceService.playVoiceMessage(widget.voiceUrl!);
                              }

                            } catch (e) {
                              print('❌ Error playing voice: $e');
                              Get.snackbar("Error", "Could not play voice message");
                            }
                          } else {
                            print('❌ No voice URL available');
                            Get.snackbar("Error", "Voice file not available");
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: isThisPlaying
                                ? LinearGradient(
                              colors: widget.isUser
                                  ? [Colors.orange.shade400, Colors.deepOrange.shade500]
                                  : [Colors.green.shade400, Colors.teal.shade500],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : LinearGradient(
                              colors: widget.isUser
                                  ? [Colors.blue.shade400, Colors.blue.shade600]
                                  : [Colors.grey.shade500, Colors.grey.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isThisPlaying
                                    ? (widget.isUser ? Colors.orange : Colors.green).withOpacity(0.4)
                                    : Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isThisPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              SizedBox(width: 12),

              // Enhanced animated waveform with multiple colors
              Expanded(
                child: Container(
                  height: 40,
                  child: Obx(() {
                    final isThisPlaying = widget.voiceUrl != null &&
                        widget.voiceUrl!.isNotEmpty &&
                        widget.voiceService.isPlaying.value &&
                        widget.voiceService.currentPlayingUrl.value == widget.voiceUrl;

                    return AnimatedBuilder(
                      animation: Listenable.merge([
                        _waveAnimation,
                        _colorAnimationController,
                      ]),
                      builder: (context, child) {
                        return Row(
                          children: List.generate(_waveCount, (index) {
                            double baseHeight = _waveHeights[index];
                            double animatedHeight = baseHeight;

                            if (isThisPlaying) {
                              // Create more complex wave pattern
                              double waveOffset = (_waveAnimation.value) + (index * 0.3);
                              double multiplier1 = (1 + math.sin(waveOffset)) / 2;
                              double multiplier2 = (1 + math.cos(waveOffset * 0.7)) / 2;
                              double finalMultiplier = (multiplier1 * 0.7 + multiplier2 * 0.3);

                              animatedHeight = baseHeight * (0.3 + finalMultiplier * 0.7);

                              // Add some randomness for more natural feel
                              if (index % 4 == 0) {
                                animatedHeight *= 1.2;
                              }
                            } else {
                              // Static wave when not playing
                              animatedHeight = baseHeight * 0.4;
                            }

                            Color waveColor = _getWaveColor(index, isThisPlaying);

                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 1),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 100),
                                  height: animatedHeight.clamp(6.0, 32.0),
                                  decoration: BoxDecoration(
                                    gradient: isThisPlaying
                                        ? LinearGradient(
                                      colors: [
                                        waveColor,
                                        waveColor.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                        : null,
                                    color: isThisPlaying ? null : waveColor,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: isThisPlaying
                                        ? [
                                      BoxShadow(
                                        color: waveColor.withOpacity(0.4),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                        : [],
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    );
                  }),
                ),
              ),

              SizedBox(width: 12),

              // Enhanced duration display
              Obx(() {
                final isThisPlaying = widget.voiceUrl != null &&
                    widget.voiceUrl!.isNotEmpty &&
                    widget.voiceService.isPlaying.value &&
                    widget.voiceService.currentPlayingUrl.value == widget.voiceUrl;

                final duration = widget.voiceService.totalDuration.value;
                final position = widget.voiceService.playbackPosition.value;

                String timeText = "0:15"; // Default duration

                if (isThisPlaying && duration.inSeconds > 0) {
                  final remaining = duration - position;
                  final minutes = remaining.inMinutes;
                  final seconds = remaining.inSeconds % 60;
                  timeText = "$minutes:${seconds.toString().padLeft(2, '0')}";
                } else if (duration.inSeconds > 0) {
                  // Show total duration when not playing
                  final minutes = duration.inMinutes;
                  final seconds = duration.inSeconds % 60;
                  timeText = "$minutes:${seconds.toString().padLeft(2, '0')}";
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isThisPlaying
                        ? (widget.isUser ? Colors.orange.shade100 : Colors.green.shade100)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isThisPlaying
                          ? (widget.isUser ? Colors.orange.shade800 : Colors.green.shade800)
                          : Colors.grey.shade600,
                      fontWeight: isThisPlaying ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: 6),
          Text(
            widget.timestamp,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}