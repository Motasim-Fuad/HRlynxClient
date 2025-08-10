
import 'package:get/get.dart';
import 'package:flutter/material.dart';
class ChatTooltipBubble extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final TextStyle textStyle;

  const ChatTooltipBubble({
    Key? key,
    required this.message,
    this.backgroundColor = const Color(0xFFB8C4C2), // like in screenshot
    this.textStyle = const TextStyle(color: Colors.black87, fontSize: 14),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Arrow pointing up
        CustomPaint(
          size: const Size(20, 10),
          painter: _TooltipArrowPainter(color: backgroundColor),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(message, style: textStyle),
        ),
      ],
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final Color color;

  _TooltipArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}



class ChatTooltipController extends GetxController {

  final isVisible = false.obs;
  void hide() => isVisible.value = false;
  void show() => isVisible.value = true;
  void toggle() => isVisible.toggle();
}