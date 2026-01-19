// lib/app/common_widgets/loading_overlay.dart

import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Show loading with custom message
  static void show({String message = 'Please wait...'}) {
    if (_isShowing) return;

    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primarycolor,),
                SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(Get.overlayContext!)?.insert(_overlayEntry!);
  }

  /// Hide loading overlay
  static void hide() {
    if (!_isShowing) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  /// Update message while loading is shown
  static void updateMessage(String message) {
    if (!_isShowing) return;

    hide();
    show(message: message);
  }
}