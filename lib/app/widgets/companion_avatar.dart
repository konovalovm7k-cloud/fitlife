import 'package:flutter/material.dart';

import '../fitlife_theme.dart';
import '../state/today_guidance.dart';

class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({super.key, this.mood = CompanionMood.welcoming});
  final CompanionMood mood;

  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (mood) {
      CompanionMood.welcoming => 'Панда рада знакомству',
      CompanionMood.attentive => 'Панда рядом и помогает',
      CompanionMood.encouraging => 'Панда поддерживает тебя',
    },
    child: SizedBox.square(
      dimension: 46,
      child: CustomPaint(painter: _PandaPainter(mood)),
    ),
  );
}

class _PandaPainter extends CustomPainter {
  const _PandaPainter(this.mood);
  final CompanionMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 46);
    final dark = Paint()..color = greenDark;
    final light = Paint()..color = const Color(0xFFF6F8EE);
    canvas.drawCircle(const Offset(11, 11), 8, dark);
    canvas.drawCircle(const Offset(35, 11), 8, dark);
    canvas.drawOval(const Rect.fromLTWH(3, 8, 40, 34), light);
    canvas.drawOval(const Rect.fromLTWH(9, 18, 11, 14), dark);
    canvas.drawOval(const Rect.fromLTWH(26, 18, 11, 14), dark);
    canvas.drawCircle(const Offset(16, 23), 2, light);
    canvas.drawCircle(const Offset(30, 23), 2, light);
    if (mood == CompanionMood.encouraging) {
      final blush = Paint()..color = coral.withValues(alpha: .55);
      canvas.drawCircle(const Offset(10, 32), 3, blush);
      canvas.drawCircle(const Offset(36, 32), 3, blush);
    }
    if (mood == CompanionMood.attentive) {
      canvas.drawCircle(const Offset(30, 22), 1, dark);
    }
    canvas.drawOval(const Rect.fromLTWH(20, 29, 6, 4), dark);
    canvas.drawArc(
      const Rect.fromLTWH(18, 28, 10, 9),
      0.4,
      2.3,
      false,
      Paint()
        ..color = greenDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PandaPainter oldDelegate) => oldDelegate.mood != mood;
}
