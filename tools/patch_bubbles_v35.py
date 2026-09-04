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
    "  final _player = AudioPlayer();\n  Timer? _timer;\n  late final AnimationController _float;\n  late final AnimationController _jump;\n",
    "  final _player = AudioPlayer();\n  final _clockPlayer = AudioPlayer();\n  Timer? _timer;\n  late final AnimationController _float;\n  late final AnimationController _jump;\n",
    'clock player',
)
rep(
    "  int _remaining = 60;\n  int _questionRemaining = 6;\n  int _step = 0;\n",
    "  int _remaining = 60;\n  int _questionRemaining = 6;\n  int _questionLimit = 6;\n  int _step = 0;\n",
    'question limit',
)
rep(
    "  final Set<int> _popped = <int>{};\n\n  static const int _goal = 10;\n",
    "  final Set<int> _popped = <int>{};\n  final Map<int, int> _stepDamage = <int, int>{};\n  int _lastAlertSecond = -1;\n\n  static const int _goal = 10;\n",
    'damage state',
)
rep(
    "    _jump.dispose();\n    _player.dispose();\n    super.dispose();\n",
    "    _jump.dispose();\n    _player.dispose();\n    _clockPlayer.dispose();\n    super.dispose();\n",
    'dispose clock',
)
rep(
    """  Future<void> _play(String name, {double volume = .5}) async {
    if (!widget.soundOn) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/$name'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  void _start() {
""",
    """  Future<void> _play(String name, {double volume = .5}) async {
    if (!widget.soundOn) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/$name'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _playClock(String name, {double volume = .45}) async {
    if (!widget.soundOn) return;
    try {
      await _clockPlayer.stop();
      await _clockPlayer.setVolume(volume);
      await _clockPlayer.play(AssetSource('sounds/$name'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  void _damageCurrentStep({bool severe = false}) {
    final index = math.min(_step, _goal - 1);
    setState(() {
      final current = _stepDamage[index] ?? 0;
      _stepDamage[index] = math.min(3, current + (severe ? 2 : 1));
    });
    if (widget.hapticOn) {
      severe ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
    }
    _playClock('escalon_crack.wav', volume: severe ? .56 : .42);
  }

  void _clockWarning() {
    if (_questionRemaining <= 0 || _questionRemaining > 3 || _lastAlertSecond == _questionRemaining) return;
    _lastAlertSecond = _questionRemaining;
    if (_questionRemaining == 1) {
      _playClock('reloj_alarma.wav', volume: .58);
      if (widget.hapticOn) HapticFeedback.selectionClick();
    } else {
      _playClock('reloj_tick.wav', volume: .38);
    }
  }

  void _start() {
""",
    'clock helpers',
)
rep(
    """  void _start() {
    if (_started) return;
    setState(() => _started = true);
    if (widget.hapticOn) HapticFeedback.selectionClick();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _finish();
        return;
      }
      setState(() {
        _remaining--;
        _questionRemaining--;
      });
      if (_questionRemaining <= 0) {
        setState(() {
          _surprised = true;
          _happy = false;
        });
        Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted && !_finished) _newQuestion();
        });
      }
    });
  }
""",
    """  void _start() {
    if (_started) return;
    setState(() => _started = true);
    if (widget.hapticOn) HapticFeedback.selectionClick();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _finish();
        return;
      }
      setState(() {
        _remaining--;
        _questionRemaining--;
      });

      if (_questionRemaining <= 0) {
        _damageCurrentStep(severe: true);
        setState(() {
          _surprised = true;
          _happy = false;
        });
        _playClock('reloj_alarma.wav', volume: .62);
        Future.delayed(const Duration(milliseconds: 520), () {
          if (mounted && !_finished) _newQuestion();
        });
      } else {
        _clockWarning();
      }

      if (_remaining <= 5 && _remaining > 0 && _questionRemaining > 3) {
        _playClock('reloj_tick.wav', volume: .34);
      }
    });
  }
""",
    'timer behavior',
)
rep(
    "      _questionRemaining = math.max(3, 6 - (_step ~/ 4));\n      _happy = false;\n",
    "      _questionLimit = math.max(3, 6 - (_step ~/ 4));\n      _questionRemaining = _questionLimit;\n      _lastAlertSecond = -1;\n      _happy = false;\n",
    'question timing',
)
rep(
    """    } else {
      setState(() {
        _wrong++;
        _happy = false;
        _surprised = true;
      });
      if (widget.hapticOn) HapticFeedback.selectionClick();
""",
    """    } else {
      _damageCurrentStep();
      setState(() {
        _wrong++;
        _happy = false;
        _surprised = true;
      });
      if (widget.hapticOn) HapticFeedback.selectionClick();
""",
    'wrong cracks step',
)
rep(
    "      _questionRemaining = 6;\n      _step = 0;\n",
    "      _questionRemaining = 6;\n      _questionLimit = 6;\n      _step = 0;\n",
    'retry limit',
)
rep(
    "      _surprised = false;\n    });\n    _newQuestion();\n",
    "      _surprised = false;\n      _stepDamage.clear();\n      _lastAlertSecond = -1;\n    });\n    _newQuestion();\n",
    'retry damage',
)
rep(
    """              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEE7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Text('Revienta la respuesta correcta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8B6F66))),
                    const SizedBox(height: 3),
                    Text(_question, style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 3),
                    Text('Esta pregunta cambia en $_questionRemaining s', style: const TextStyle(fontSize: 11.5, color: Color(0xFF8B6F66))),
                  ],
                ),
              ),
""",
    """              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _started && !_finished && _questionRemaining <= 3
                        ? const [Color(0xFFFFE1D8), Color(0xFFFFF2EC)]
                        : const [Color(0xFFFFEEE7), Color(0xFFFFF8F4)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _started && !_finished && _questionRemaining <= 3 ? _red.withValues(alpha: .65) : const Color(0xFFF3D9CF),
                    width: _started && !_finished && _questionRemaining <= 3 ? 2 : 1,
                  ),
                  boxShadow: _started && !_finished && _questionRemaining <= 2
                      ? [BoxShadow(color: _red.withValues(alpha: .16), blurRadius: 18, spreadRadius: 2)]
                      : const [],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _started && !_finished && _questionRemaining <= 3 ? '⚠️ ¡RÁPIDO, MOTI ESTÁ NERVIOSO!' : '🧠 RESUELVE ESTA OPERACIÓN',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                              color: _started && !_finished && _questionRemaining <= 3 ? _redDark : const Color(0xFF8B6F66),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(_question, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _ink)),
                          const SizedBox(height: 4),
                          Text(
                            _started && !_finished
                                ? (_questionRemaining <= 1 ? '¡Último segundo! El escalón puede quebrarse.' : 'Revienta la burbuja correcta antes de que suene la alarma.')
                                : 'Revienta la burbuja con la respuesta correcta.',
                            style: const TextStyle(fontSize: 11.5, height: 1.25, color: Color(0xFF7D6963)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _QuestionClock(
                      remaining: _questionRemaining,
                      limit: _questionLimit,
                      active: _started && !_finished,
                    ),
                  ],
                ),
              ),
""",
    'question clock card',
)
rep(
    """                    SizedBox(
                      width: 112,
                      child: AnimatedBuilder(
                        animation: _jump,
                        builder: (context, _) => _StairMoti(
                          step: _step,
                          goal: _goal,
                          jump: math.sin(_jump.value * math.pi) * 18,
                          happy: _happy,
                          surprised: _surprised,
                          finished: _finished && _won,
                        ),
                      ),
                    ),
""",
    """                    SizedBox(
                      width: 122,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_jump, _float]),
                        builder: (context, _) {
                          final nervousLevel = _started && !_finished && _questionRemaining <= 3
                              ? math.max(0, 4 - _questionRemaining)
                              : 0;
                          final shake = nervousLevel > 0
                              ? math.sin(_float.value * math.pi * 12) * nervousLevel * 1.7
                              : 0.0;
                          return _StairMoti(
                            step: _step,
                            goal: _goal,
                            jump: math.sin(_jump.value * math.pi) * 18,
                            happy: _happy,
                            surprised: _surprised,
                            finished: _finished && _won,
                            stepDamage: _stepDamage,
                            nervousLevel: nervousLevel,
                            shake: shake,
                          );
                        },
                      ),
                    ),
""",
    'nervous stair moti',
)
rep(
    "class _Pill extends StatelessWidget {\n",
    """class _QuestionClock extends StatelessWidget {
  const _QuestionClock({required this.remaining, required this.limit, required this.active});

  final int remaining;
  final int limit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final safeLimit = math.max(1, limit);
    final progress = (remaining / safeLimit).clamp(0.0, 1.0).toDouble();
    final danger = active && remaining <= 3;
    final critical = active && remaining <= 1;
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: critical ? 1.08 : 1,
      child: Container(
        width: 82,
        height: 82,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: danger ? _red : const Color(0xFFF0C7B9), width: danger ? 2.2 : 1.2),
          boxShadow: danger ? [BoxShadow(color: _red.withValues(alpha: .2), blurRadius: 13)] : const [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                color: danger ? _red : const Color(0xFFFFA54B),
                backgroundColor: const Color(0xFFFFE5DC),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(critical ? Icons.alarm_on_rounded : Icons.timer_rounded, size: 17, color: danger ? _redDark : _ink),
                Text('$remaining', style: TextStyle(fontSize: 22, height: .95, fontWeight: FontWeight.w900, color: danger ? _redDark : _ink)),
                Text('seg', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: danger ? _redDark : const Color(0xFF8B6F66))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
""",
    'question clock widget',
)

start = s.find('class _StairMoti extends StatelessWidget {')
if start < 0:
    raise SystemExit('stair class not found')

s = s[:start] + r'''class _StairMoti extends StatelessWidget {
  const _StairMoti({
    required this.step,
    required this.goal,
    required this.jump,
    required this.happy,
    required this.surprised,
    required this.finished,
    required this.stepDamage,
    required this.nervousLevel,
    required this.shake,
  });

  final int step;
  final int goal;
  final double jump;
  final bool happy;
  final bool surprised;
  final bool finished;
  final Map<int, int> stepDamage;
  final int nervousLevel;
  final double shake;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final usable = math.max(150.0, box.maxHeight - 80);
        final gap = usable / goal;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < goal; i++)
              Positioned(
                left: 5 + i * 4.5,
                bottom: 16 + i * gap,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('step-$i-${stepDamage[i] ?? 0}'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  builder: (context, t, child) {
                    final damage = stepDamage[i] ?? 0;
                    final pulse = damage > 0 ? math.sin(t * math.pi) * .13 : 0.0;
                    return Transform.scale(scale: 1 - pulse, child: child);
                  },
                  child: CustomPaint(
                    size: Size(94 - i * 4.0, 13),
                    painter: _StepPainter(damage: stepDamage[i] ?? 0),
                  ),
                ),
              ),
            Positioned(
              right: 5,
              top: 3,
              child: Column(children: const [Text('⭐', style: TextStyle(fontSize: 25)), Text('META', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _redDark))]),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              left: 12 + step * 3.8,
              bottom: 24 + math.min(step, goal - 1) * gap + jump,
              child: Transform.translate(
                offset: Offset(shake, 0),
                child: CustomPaint(
                  size: const Size(58, 70),
                  painter: _MiniMotiPainter(
                    happy: happy || finished,
                    surprised: surprised,
                    tongue: finished,
                    nervousLevel: nervousLevel,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StepPainter extends CustomPainter {
  const _StepPainter({required this.damage});
  final int damage;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColors = <Color>[
      const Color(0xFFE2C5B9),
      const Color(0xFFE7B89F),
      const Color(0xFFE58B72),
      const Color(0xFFC85B47),
    ];
    final paint = Paint()..color = baseColors[damage.clamp(0, 3)];
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)), paint);
    if (damage <= 0) return;

    final crack = Paint()
      ..color = const Color(0xFF7E4638)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    final x = size.width * .43;
    final p1 = Path()
      ..moveTo(x, 1)
      ..lineTo(x - 4, 4.5)
      ..lineTo(x + 2, 7)
      ..lineTo(x - 2, size.height - 1);
    canvas.drawPath(p1, crack);

    if (damage >= 2) {
      canvas.drawPath(Path()..moveTo(x + 1, 6)..lineTo(x + 8, 4)..lineTo(x + 13, 7.5), crack);
      canvas.drawPath(Path()..moveTo(x - 1, 7)..lineTo(x - 9, 9.5)..lineTo(x - 14, 7.5), crack);
    }

    if (damage >= 3) {
      final chip = Paint()..color = const Color(0xFFF8F1ED);
      canvas.drawCircle(Offset(size.width * .73, 2.5), 3.5, chip);
      canvas.drawCircle(Offset(size.width * .78, size.height - 1), 2.8, chip);
      final crumb = Paint()..color = const Color(0xFFB96550);
      canvas.drawCircle(Offset(size.width * .71, size.height + 4), 2.2, crumb);
      canvas.drawCircle(Offset(size.width * .79, size.height + 6), 1.5, crumb);
    }
  }

  @override
  bool shouldRepaint(covariant _StepPainter oldDelegate) => oldDelegate.damage != damage;
}

class _MiniMotiPainter extends CustomPainter {
  const _MiniMotiPainter({required this.happy, required this.surprised, required this.tongue, required this.nervousLevel});
  final bool happy;
  final bool surprised;
  final bool tongue;
  final int nervousLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = _red;
    final dark = Paint()..color = _redDark;
    final ink = Paint()..color = _ink;
    final white = Paint()..color = Colors.white;
    final leaf = Paint()..color = _leaf;
    final center = Offset(size.width / 2, size.height * .58);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 45, height: 49), const Radius.circular(18)), body);
    final leafPath = Path()..moveTo(28, 18)..quadraticBezierTo(35, 1, 52, 8)..quadraticBezierTo(42, 22, 28, 18)..close();
    canvas.drawPath(leafPath, leaf);

    final nervous = nervousLevel > 0 && !happy && !surprised;
    if (surprised) {
      canvas.drawCircle(const Offset(21, 36), 5.1, white);
      canvas.drawCircle(const Offset(37, 36), 5.1, white);
      canvas.drawCircle(const Offset(21, 36), 2.5, ink);
      canvas.drawCircle(const Offset(37, 36), 2.5, ink);
      canvas.drawCircle(const Offset(29, 49), 5.2, dark);
    } else if (happy) {
      final pen = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: const Offset(21, 37), width: 11, height: 8), 0, math.pi, false, pen);
      canvas.drawArc(Rect.fromCenter(center: const Offset(37, 37), width: 11, height: 8), 0, math.pi, false, pen);
      canvas.drawOval(Rect.fromCenter(center: const Offset(29, 49), width: 20, height: 14), dark);
      canvas.drawRect(const Rect.fromLTWH(21, 44, 15, 4), white);
      if (tongue) canvas.drawOval(Rect.fromCenter(center: const Offset(29, 53), width: 10, height: 5), Paint()..color = const Color(0xFFFF8CA0));
    } else if (nervous) {
      final eyeRadius = nervousLevel >= 2 ? 5.2 : 4.4;
      canvas.drawCircle(const Offset(21, 36), eyeRadius, white);
      canvas.drawCircle(const Offset(37, 36), eyeRadius, white);
      canvas.drawCircle(const Offset(22, 37), 2.5, ink);
      canvas.drawCircle(const Offset(36, 37), 2.5, ink);
      final brow = Paint()..color = _ink..strokeWidth = 2.4..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(16, 29), const Offset(24, 31), brow);
      canvas.drawLine(const Offset(34, 31), const Offset(42, 29), brow);
      final mouth = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 2.7..strokeCap = StrokeCap.round;
      canvas.drawPath(Path()..moveTo(21, 50)..quadraticBezierTo(25, 46, 29, 50)..quadraticBezierTo(33, 54, 38, 50), mouth);
      if (nervousLevel >= 2) {
        final sweat = Paint()..color = const Color(0xFFBFE8FF);
        final drop = Path()..moveTo(47, 31)..quadraticBezierTo(53, 38, 47, 42)..quadraticBezierTo(41, 38, 47, 31)..close();
        canvas.drawPath(drop, sweat);
      }
    } else {
      canvas.drawCircle(const Offset(21, 37), 2.8, ink);
      canvas.drawCircle(const Offset(37, 37), 2.8, ink);
      final smile = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 2.8..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: const Offset(29, 48), width: 16, height: 10), .1, math.pi - .2, false, smile);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMotiPainter oldDelegate) =>
      oldDelegate.happy != happy || oldDelegate.surprised != surprised || oldDelegate.tongue != tongue || oldDelegate.nervousLevel != nervousLevel;
}
'''

p.write_text(s, encoding='utf-8')
print(f'Patched {p} with v3.5 bubbles tension mechanics')
