import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VoiceRecordingWidget extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final String duration;

  const VoiceRecordingWidget({
    Key? key,
    required this.onCancel,
    required this.onSend,
    required this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 20, color: Colors.grey.shade700),
            ),
          ),

          SizedBox(width: 12),

          // Recording animation
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: TweenAnimationBuilder(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: Duration(milliseconds: 800),
              // repeat: true,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(width: 12),

          // Recording text and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Recording...",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}