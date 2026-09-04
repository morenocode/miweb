from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')

def rep(old, new, label):
    global s
    if old not in s:
        raise SystemExit(f'{label} marker not found')
    s = s.replace(old, new, 1)

rep(
    "  Timer? _timer;\n  late final AnimationController _idle;\n",
    "  Timer? _timer;\n  Timer? _blinkTimer;\n  late final AnimationController _idle;\n",
    'blink timer field',
)
rep(
    "  bool _finished = false;\n  bool _started = false;\n",
    "  bool _finished = false;\n  bool _started = false;\n  bool _blink = false;\n",
    'blink state',
)
rep(
    "    _reaction = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));\n  }\n",
    """    _reaction = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 2300), (_) {
      if (!mounted || _finished) return;
      setState(() => _blink = true);
      Future.delayed(const Duration(milliseconds: 135), () {
        if (mounted) setState(() => _blink = false);
      });
    });
  }
""",
    'blink init',
)
rep(
    "    _timer?.cancel();\n    _idle.dispose();\n",
    "    _timer?.cancel();\n    _blinkTimer?.cancel();\n    _idle.dispose();\n",
    'blink dispose',
)
rep(
    "                            painter: _TickleMotiPainter(level: _laughLevel, finished: _finished),\n",
    "                            painter: _TickleMotiPainter(level: _laughLevel, finished: _finished, blink: _blink, lookRight: _lastSide == 'derecho'),\n",
    'painter args',
)
rep(
    "class _TickleMotiPainter extends CustomPainter {\n  const _TickleMotiPainter({required this.level, required this.finished});\n\n  final int level;\n  final bool finished;\n",
    "class _TickleMotiPainter extends CustomPainter {\n  const _TickleMotiPainter({required this.level, required this.finished, required this.blink, required this.lookRight});\n\n  final int level;\n  final bool finished;\n  final bool blink;\n  final bool lookRight;\n",
    'painter fields',
)
old_eyes = """    if (level >= 2 || finished) {
      final eyePen = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: leftEye, width: 28, height: 20), math.pi * .10, math.pi * .80, false, eyePen);
      canvas.drawArc(Rect.fromCenter(center: rightEye, width: 28, height: 20), math.pi * .10, math.pi * .80, false, eyePen);
    } else {
      canvas.drawCircle(leftEye, 8, Paint()..color = _ink);
      canvas.drawCircle(rightEye, 8, Paint()..color = _ink);
      canvas.drawCircle(leftEye.translate(-2, -2), 2.2, white);
      canvas.drawCircle(rightEye.translate(-2, -2), 2.2, white);
    }
"""
new_eyes = """    final eyePen = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    if (blink || level >= 3 || finished) {
      canvas.drawArc(Rect.fromCenter(center: leftEye, width: 31, height: 19), .08, math.pi - .16, false, eyePen);
      canvas.drawArc(Rect.fromCenter(center: rightEye, width: 31, height: 19), .08, math.pi - .16, false, eyePen);
    } else {
      final eyeRadius = level >= 1 ? 13.0 : 11.0;
      canvas.drawOval(Rect.fromCenter(center: leftEye, width: eyeRadius * 1.45, height: eyeRadius * 1.8), white);
      canvas.drawOval(Rect.fromCenter(center: rightEye, width: eyeRadius * 1.45, height: eyeRadius * 1.8), white);
      final pupilDx = lookRight ? 2.8 : -2.8;
      final pupilY = level >= 2 ? 1.5 : 0.0;
      final pupil = Paint()..color = _ink;
      canvas.drawCircle(leftEye.translate(pupilDx, pupilY), level >= 1 ? 5.2 : 4.5, pupil);
      canvas.drawCircle(rightEye.translate(pupilDx, pupilY), level >= 1 ? 5.2 : 4.5, pupil);
      canvas.drawCircle(leftEye.translate(pupilDx - 1.7, pupilY - 2), 1.7, white);
      canvas.drawCircle(rightEye.translate(pupilDx - 1.7, pupilY - 2), 1.7, white);
    }
"""
rep(old_eyes, new_eyes, 'eyes')
old_mouth = """    final mouthCenter = Offset(size.width * .50, size.height * .62);
    if (level == 0) {
      final smile = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: mouthCenter, width: 48, height: 30), .15, math.pi - .30, false, smile);
    } else if (level == 1) {
      final smile = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: mouthCenter, width: 64, height: 40), .05, math.pi - .10, false, smile);
    } else {
      canvas.drawOval(Rect.fromCenter(center: mouthCenter.translate(0, 5), width: 66 + level * 5, height: 48 + level * 4), dark);
      canvas.drawArc(Rect.fromCenter(center: mouthCenter.translate(0, 0), width: 48, height: 25), .1, math.pi - .2, false, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 7);
    }
"""
new_mouth = """    final mouthCenter = Offset(size.width * .50, size.height * .62);
    if (level == 0) {
      final smile = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: mouthCenter, width: 50, height: 31), .15, math.pi - .30, false, smile);
    } else {
      final width = 62.0 + level * 7.0;
      final height = 39.0 + level * 7.5;
      final mouthRect = Rect.fromCenter(center: mouthCenter.translate(0, 6), width: width, height: height);
      canvas.drawOval(mouthRect, dark);
      final teethRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(mouthRect.left + 9, mouthRect.top + 6, mouthRect.width - 18, math.max(8, mouthRect.height * .25)),
        const Radius.circular(5),
      );
      canvas.drawRRect(teethRect, white);
      if (level >= 3 || finished) {
        final tongue = Paint()..color = const Color(0xFFFF8297);
        final tongueRect = Rect.fromCenter(
          center: Offset(mouthCenter.dx, mouthRect.bottom - 8),
          width: mouthRect.width * .48,
          height: mouthRect.height * .27,
        );
        canvas.drawOval(tongueRect, tongue);
        canvas.drawLine(
          Offset(mouthCenter.dx, tongueRect.top + 2),
          Offset(mouthCenter.dx, tongueRect.bottom - 1),
          Paint()..color = const Color(0xFFE45F76)..strokeWidth = 2,
        );
      }
    }
"""
rep(old_mouth, new_mouth, 'mouth')
rep(
    "  bool shouldRepaint(covariant _TickleMotiPainter oldDelegate) => oldDelegate.level != level || oldDelegate.finished != finished;\n",
    "  bool shouldRepaint(covariant _TickleMotiPainter oldDelegate) => oldDelegate.level != level || oldDelegate.finished != finished || oldDelegate.blink != blink || oldDelegate.lookRight != lookRight;\n",
    'repaint',
)

p.write_text(s, encoding='utf-8')
print(f'Patched {p} with expressive Moti face')
