import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _red = Color(0xFFF04432);
const _redDark = Color(0xFFC92F22);
const _leaf = Color(0xFF45A85D);
const _ink = Color(0xFF3D2722);

class MotiMinuteCard extends StatelessWidget {
  const MotiMinuteCard({
    super.key,
    required this.unlocked,
    required this.done,
    required this.moodLabel,
    required this.onStart,
  });

  final bool unlocked;
  final bool done;
  final String? moodLabel;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final title = moodLabel == 'Triste' ? 'Haz reír a Moti' : '1 minuto con Moti';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFFFF4CF) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: done ? const Color(0xFFFFD76B) : const Color(0xFFF0DDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(done ? '🥭' : unlocked ? '😆' : '🔒', style: const TextStyle(fontSize: 27)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(
                      done
                          ? 'Ya compartiste tu minuto de hoy con Moti.'
                          : unlocked
                              ? 'La misión abrió un momento especial. Hazle cosquillas y mira cómo reacciona.'
                              : 'Completa primero la misión que Moti te propuso.',
                      style: const TextStyle(fontSize: 12.2, height: 1.35, color: Color(0xFF82736E)),
                    ),
                  ],
                ),
              ),
              if (done) const Text('+5 ⭐', style: TextStyle(fontWeight: FontWeight.w900, color: _redDark)),
            ],
          ),
          if (unlocked && !done) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text('Empezar 1 minuto con Moti'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MotiMinutePage extends StatefulWidget {
  const MotiMinutePage({
    super.key,
    required this.moodLabel,
    required this.moodEmoji,
    required this.soundOn,
    required this.hapticOn,
  });

  final String moodLabel;
  final String moodEmoji;
  final bool soundOn;
  final bool hapticOn;

  @override
  State<MotiMinutePage> createState() => _MotiMinutePageState();
}

class _MotiMinutePageState extends State<MotiMinutePage> with TickerProviderStateMixin {
  final _laughPlayer = AudioPlayer();
  Timer? _timer;
  late final AnimationController _idle;
  late final AnimationController _reaction;
  int _remaining = 60;
  int _taps = 0;
  bool _finished = false;
  bool _started = false;
  String _lastSide = 'derecho';

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
    _reaction = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _idle.dispose();
    _reaction.dispose();
    _laughPlayer.dispose();
    super.dispose();
  }

  String get _intro {
    switch (widget.moodLabel) {
      case 'Triste':
        return 'Hoy Moti quiere devolverte un poquito de juego. Hazle cosquillas en los costados.';
      case 'Ansioso':
        return 'Durante un minuto, deja lo demás afuera. Solo juega con Moti y vuelve al presente.';
      case 'Enojado':
        return 'Vamos a transformar un poco de tensión en juego. Moti está listo para las cosquillas.';
      case 'Cansado':
        return 'Nada complicado: un minuto suave para jugar con Moti antes de seguir.';
      case 'Feliz':
        return 'Comparte tu buen ánimo con Moti. A ver cuánto logras hacerlo reír.';
      default:
        return 'Un minuto, tú y Moti. Toca sus costados y descubre cómo cambia su reacción.';
    }
  }

  String get _phaseText {
    if (!_started) return 'Toca “Comenzar” cuando estés listo.';
    if (_finished) return '¡Lo lograste! Moti terminó riéndose contigo.';
    if (_remaining > 45) return _taps < 4 ? 'Moti intenta aguantar la risa…' : 'Je, je… creo que encontraste el punto.';
    if (_remaining > 25) return _taps < 10 ? 'Prueba ambos costados.' : '¡Jajaja! Moti ya no puede quedarse quieto.';
    if (_remaining > 10) return _taps < 18 ? 'Unas cosquillas más…' : '¡JA JA! Moti está completamente rendido.';
    return 'Últimos segundos… Moti respira y sigue sonriendo contigo.';
  }

  int get _laughLevel {
    if (_taps >= 24) return 4;
    if (_taps >= 15) return 3;
    if (_taps >= 8) return 2;
    if (_taps >= 3) return 1;
    return 0;
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    if (widget.hapticOn) HapticFeedback.selectionClick();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _finished = true;
        });
        if (widget.hapticOn) HapticFeedback.heavyImpact();
        _playLaugh(force: true);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _playLaugh({bool force = false}) async {
    if (!widget.soundOn) return;
    final threshold = _taps == 4 || _taps == 9 || _taps == 16 || (_taps >= 22 && _taps % 6 == 0);
    if (!force && !threshold) return;
    try {
      await _laughPlayer.stop();
      await _laughPlayer.setVolume(.48);
      await _laughPlayer.play(AssetSource('sounds/moti_risa.wav'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  void _tickle(String side) {
    if (!_started || _finished) return;
    setState(() {
      _taps++;
      _lastSide = side;
    });
    if (widget.hapticOn) HapticFeedback.lightImpact();
    _reaction.forward(from: 0);
    _playLaugh();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / 60;
    return Scaffold(
      appBar: AppBar(
        title: const Text('1 minuto con Moti', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: [
              Text(widget.moodEmoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 3),
              Text(_intro, textAlign: TextAlign.center, style: const TextStyle(height: 1.35, color: Color(0xFF6E5F5A), fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(value: progress, minHeight: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${_remaining}s', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_idle, _reaction]),
                    builder: (context, child) {
                      final idleY = math.sin(_idle.value * math.pi * 2) * 3.2;
                      final wiggle = math.sin(_reaction.value * math.pi * 5) * (0.035 + _laughLevel * 0.008);
                      final bounce = math.sin(_reaction.value * math.pi) * (5 + _laughLevel * 1.5);
                      final scale = 1 + math.sin(_reaction.value * math.pi) * (0.025 + _laughLevel * 0.008);
                      return Transform.translate(
                        offset: Offset(0, idleY - bounce),
                        child: Transform.rotate(
                          angle: (_lastSide == 'izquierdo' ? -1 : 1) * wiggle,
                          child: Transform.scale(scale: scale, child: child),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 285,
                      height: 315,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(285, 315),
                            painter: _TickleMotiPainter(level: _laughLevel, finished: _finished),
                          ),
                          if (_started && !_finished) ...[
                            Positioned(
                              left: 8,
                              top: 95,
                              bottom: 48,
                              width: 78,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => _tickle('izquierdo'),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 95,
                              bottom: 48,
                              width: 78,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => _tickle('derecho'),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ],
                          if (_started && !_finished && _taps < 3)
                            const Positioned(
                              bottom: 14,
                              child: Row(
                                children: [
                                  Icon(Icons.touch_app_rounded, color: _redDark),
                                  SizedBox(width: 5),
                                  Text('Toca mis costados', style: TextStyle(fontWeight: FontWeight.w900, color: _redDark)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _phaseText,
                  key: ValueKey('$_remaining-$_laughLevel-$_started-$_finished'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w900, color: _ink),
                ),
              ),
              const SizedBox(height: 6),
              Text('Cosquillas: $_taps', style: const TextStyle(color: Color(0xFF8B7B76), fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              if (!_started)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Comenzar 60 segundos')),
                )
              else if (_finished)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Terminar · ganar +5 ⭐'),
                  ),
                )
              else
                const Text('Puedes alternar entre el costado izquierdo y derecho.', style: TextStyle(fontSize: 12, color: Color(0xFF8B7B76))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickleMotiPainter extends CustomPainter {
  const _TickleMotiPainter({required this.level, required this.finished});

  final int level;
  final bool finished;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = _red;
    final dark = Paint()..color = _redDark;
    final leaf = Paint()..color = _leaf;
    final blush = Paint()..color = const Color(0xFFFF8E82).withValues(alpha: .72);
    final white = Paint()..color = Colors.white;

    final center = Offset(size.width / 2, size.height * .55);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * .70, height: size.height * .62),
      const Radius.circular(88),
    );
    canvas.drawRRect(rect, body);

    final leafPath = Path()
      ..moveTo(size.width * .49, size.height * .20)
      ..quadraticBezierTo(size.width * .58, size.height * .03, size.width * .77, size.height * .12)
      ..quadraticBezierTo(size.width * .64, size.height * .28, size.width * .49, size.height * .20)
      ..close();
    canvas.drawPath(leafPath, leaf);
    canvas.drawLine(Offset(size.width * .53, size.height * .23), Offset(size.width * .64, size.height * .10), Paint()..color = const Color(0xFF328446)..strokeWidth = 7..strokeCap = StrokeCap.round);

    final eyeY = size.height * .49;
    final leftEye = Offset(size.width * .40, eyeY);
    final rightEye = Offset(size.width * .60, eyeY);

    if (level >= 2 || finished) {
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

    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .31, size.height * .59), width: 34, height: 18), blush);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .69, size.height * .59), width: 34, height: 18), blush);

    final mouthCenter = Offset(size.width * .50, size.height * .62);
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

    final arm = Paint()..color = _redDark..strokeWidth = 12..strokeCap = StrokeCap.round;
    final armLift = level >= 3 ? -26.0 : level >= 1 ? -10.0 : 8.0;
    canvas.drawLine(Offset(size.width * .23, size.height * .58), Offset(size.width * .10, size.height * .62 + armLift), arm);
    canvas.drawLine(Offset(size.width * .77, size.height * .58), Offset(size.width * .90, size.height * .62 + armLift), arm);

    if (level >= 3 || finished) {
      final sparkle = Paint()..color = const Color(0xFFFFC928);
      for (final offset in [const Offset(.14, .32), const Offset(.86, .30), const Offset(.20, .82), const Offset(.82, .80)]) {
        final p = Offset(size.width * offset.dx, size.height * offset.dy);
        canvas.drawCircle(p, 5, sparkle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TickleMotiPainter oldDelegate) => oldDelegate.level != level || oldDelegate.finished != finished;
}
