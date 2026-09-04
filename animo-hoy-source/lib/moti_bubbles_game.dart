import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _red = Color(0xFFF04432);
const _redDark = Color(0xFFC92F22);
const _ink = Color(0xFF3D2722);
const _leaf = Color(0xFF45A85D);

class MotiGameCard extends StatelessWidget {
  const MotiGameCard({super.key, required this.doneToday, required this.onStart});

  final bool doneToday;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFF0DDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🫧', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Burbujas de Moti', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    Text('Revienta la respuesta correcta y haz que Moti suba los escalones.', style: TextStyle(fontSize: 12.2, height: 1.35, color: Color(0xFF82736E))),
                  ],
                ),
              ),
              if (doneToday) const Text('⭐ +10', style: TextStyle(fontWeight: FontWeight.w900, color: _redDark)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.sports_esports_rounded),
              label: Text(doneToday ? 'Jugar otra vez' : 'Jugar 60 segundos'),
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleMathGamePage extends StatefulWidget {
  const BubbleMathGamePage({super.key, required this.soundOn, required this.hapticOn});

  final bool soundOn;
  final bool hapticOn;

  @override
  State<BubbleMathGamePage> createState() => _BubbleMathGamePageState();
}

class _BubbleMathGamePageState extends State<BubbleMathGamePage> with TickerProviderStateMixin {
  final _random = math.Random();
  final _player = AudioPlayer();
  Timer? _timer;
  late final AnimationController _float;
  late final AnimationController _jump;

  int _remaining = 60;
  int _questionRemaining = 6;
  int _step = 0;
  int _correct = 0;
  int _wrong = 0;
  bool _started = false;
  bool _finished = false;
  bool _won = false;
  bool _happy = false;
  bool _surprised = false;
  int _answer = 0;
  String _question = '';
  List<int> _options = const [];
  final Set<int> _popped = <int>{};

  static const int _goal = 10;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _newQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _float.dispose();
    _jump.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(String name, {double volume = .5}) async {
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

  void _newQuestion() {
    int a;
    int b;
    String op;
    int answer;

    if (_step < 4) {
      if (_random.nextBool()) {
        a = 2 + _random.nextInt(12);
        b = 1 + _random.nextInt(9);
        op = '+';
        answer = a + b;
      } else {
        a = 5 + _random.nextInt(12);
        b = 1 + _random.nextInt(a - 1);
        op = '−';
        answer = a - b;
      }
    } else if (_step < 8) {
      if (_random.nextBool()) {
        a = 2 + _random.nextInt(8);
        b = 2 + _random.nextInt(8);
        op = '×';
        answer = a * b;
      } else {
        a = 8 + _random.nextInt(17);
        b = 2 + _random.nextInt(12);
        op = '+';
        answer = a + b;
      }
    } else {
      final mode = _random.nextInt(3);
      if (mode == 0) {
        a = 3 + _random.nextInt(8);
        b = 3 + _random.nextInt(8);
        op = '×';
        answer = a * b;
      } else if (mode == 1) {
        b = 2 + _random.nextInt(8);
        answer = 2 + _random.nextInt(9);
        a = answer * b;
        op = '÷';
      } else {
        a = 15 + _random.nextInt(25);
        b = 3 + _random.nextInt(13);
        op = '−';
        answer = a - b;
      }
    }

    final values = <int>{answer};
    while (values.length < 4) {
      final delta = 1 + _random.nextInt(math.max(4, answer ~/ 4 + 2));
      final candidate = math.max(0, answer + (_random.nextBool() ? delta : -delta));
      values.add(candidate);
    }
    final list = values.toList()..shuffle(_random);

    if (!mounted) return;
    setState(() {
      _question = '$a $op $b = ?';
      _answer = answer;
      _options = list;
      _popped.clear();
      _questionRemaining = math.max(3, 6 - (_step ~/ 4));
      _happy = false;
      _surprised = false;
    });
  }

  Future<void> _tapBubble(int index) async {
    if (!_started || _finished || _popped.contains(index)) return;
    final value = _options[index];
    setState(() => _popped.add(index));
    if (widget.hapticOn) HapticFeedback.lightImpact();
    await _play('burbuja_pop.wav', volume: .35);

    if (value == _answer) {
      final nextStep = math.min(_goal, _step + 1);
      setState(() {
        _correct++;
        _step = nextStep;
        _happy = true;
        _surprised = false;
      });
      if (widget.hapticOn) HapticFeedback.mediumImpact();
      _jump.forward(from: 0);
      await _play('moti_salto.wav', volume: .45);
      if (_step >= _goal) {
        Future.delayed(const Duration(milliseconds: 380), _finish);
      } else {
        Future.delayed(const Duration(milliseconds: 330), () {
          if (mounted && !_finished) _newQuestion();
        });
      }
    } else {
      setState(() {
        _wrong++;
        _happy = false;
        _surprised = true;
      });
      if (widget.hapticOn) HapticFeedback.selectionClick();
      if (_popped.length >= 3) {
        Future.delayed(const Duration(milliseconds: 280), () {
          if (mounted && !_finished) _newQuestion();
        });
      }
    }
  }

  void _finish() {
    if (_finished) return;
    _timer?.cancel();
    final won = _step >= _goal;
    setState(() {
      _finished = true;
      _won = won;
      _remaining = math.max(0, _remaining - (won ? 0 : 1));
      _happy = won;
      _surprised = !won;
    });
    if (widget.hapticOn) HapticFeedback.heavyImpact();
    _play(won ? 'moti_meta.wav' : 'moti_fin.wav', volume: won ? .58 : .35);
  }

  void _retry() {
    _timer?.cancel();
    setState(() {
      _remaining = 60;
      _questionRemaining = 6;
      _step = 0;
      _correct = 0;
      _wrong = 0;
      _started = false;
      _finished = false;
      _won = false;
      _happy = false;
      _surprised = false;
    });
    _newQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Burbujas de Moti', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _Pill(icon: '⏱️', text: '${_remaining}s')),
                  const SizedBox(width: 8),
                  Expanded(child: _Pill(icon: '✅', text: '$_correct')),
                  const SizedBox(width: 8),
                  Expanded(child: _Pill(icon: '🪜', text: '$_step/$_goal')),
                ],
              ),
              const SizedBox(height: 10),
              Container(
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
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
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
                    const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _float,
                        builder: (context, _) {
                          return LayoutBuilder(
                            builder: (context, box) {
                              final positions = <Offset>[
                                Offset(box.maxWidth * .05, box.maxHeight * .08),
                                Offset(box.maxWidth * .50, box.maxHeight * .20),
                                Offset(box.maxWidth * .12, box.maxHeight * .53),
                                Offset(box.maxWidth * .53, box.maxHeight * .62),
                              ];
                              return Stack(
                                clipBehavior: Clip.none,
                                children: List.generate(_options.length, (index) {
                                  final base = positions[index];
                                  final dy = math.sin((_float.value * math.pi * 2) + index * 1.4) * 10;
                                  final dx = math.cos((_float.value * math.pi * 2) + index * .9) * 5;
                                  final popped = _popped.contains(index);
                                  return Positioned(
                                    left: base.dx + dx,
                                    top: base.dy + dy,
                                    child: AnimatedScale(
                                      duration: const Duration(milliseconds: 170),
                                      scale: popped ? 0.05 : 1,
                                      child: AnimatedOpacity(
                                        duration: const Duration(milliseconds: 150),
                                        opacity: popped ? 0 : 1,
                                        child: _AnswerBubble(
                                          value: _options[index],
                                          index: index,
                                          enabled: _started && !_finished,
                                          onTap: () => _tapBubble(index),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!_started)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Comenzar 60 segundos'),
                  ),
                )
              else if (_finished) ...[
                Text(
                  _won ? '🏆 ¡Moti llegó a la meta!' : '⏰ Se acabó el minuto. Llegaste al escalón $_step.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: _retry, child: const Text('Reintentar'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, _won),
                        child: Text(_won ? 'Volver · +10 ⭐' : 'Volver'),
                      ),
                    ),
                  ],
                ),
              ] else
                const Text('Cada acierto hace saltar a Moti. Las burbujas incorrectas también explotan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.8, color: Color(0xFF8B7B76))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF1DDD6))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon), const SizedBox(width: 5), Text(text, style: const TextStyle(fontWeight: FontWeight.w900))]),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.value, required this.index, required this.enabled, required this.onTap});
  final int value;
  final int index;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFFFFC8D2), Color(0xFFBFE8FF), Color(0xFFCFF2D6), Color(0xFFFFE4A8)];
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [Colors.white.withValues(alpha: .95), colors[index % colors.length]]),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: colors[index % colors.length].withValues(alpha: .35), blurRadius: 16, spreadRadius: 2)],
        ),
        child: Stack(
          children: [
            const Positioned(top: 13, left: 17, child: CircleAvatar(radius: 7, backgroundColor: Colors.white70)),
            Center(child: Text('$value', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _ink))),
          ],
        ),
      ),
    );
  }
}

class _StairMoti extends StatelessWidget {
  const _StairMoti({required this.step, required this.goal, required this.jump, required this.happy, required this.surprised, required this.finished});
  final int step;
  final int goal;
  final double jump;
  final bool happy;
  final bool surprised;
  final bool finished;

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
                child: Container(
                  width: 88 - i * 4.0,
                  height: 8,
                  decoration: BoxDecoration(color: const Color(0xFFE2C5B9), borderRadius: BorderRadius.circular(10)),
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
              bottom: 22 + math.min(step, goal - 1) * gap + jump,
              child: CustomPaint(
                size: const Size(54, 66),
                painter: _MiniMotiPainter(happy: happy || finished, surprised: surprised, tongue: finished),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniMotiPainter extends CustomPainter {
  const _MiniMotiPainter({required this.happy, required this.surprised, required this.tongue});
  final bool happy;
  final bool surprised;
  final bool tongue;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = _red;
    final dark = Paint()..color = _redDark;
    final ink = Paint()..color = _ink;
    final white = Paint()..color = Colors.white;
    final leaf = Paint()..color = _leaf;
    final center = Offset(size.width / 2, size.height * .58);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 43, height: 47), const Radius.circular(18)), body);
    final leafPath = Path()..moveTo(26, 18)..quadraticBezierTo(33, 1, 49, 8)..quadraticBezierTo(40, 22, 26, 18)..close();
    canvas.drawPath(leafPath, leaf);

    if (surprised) {
      canvas.drawCircle(const Offset(20, 35), 4.8, white);
      canvas.drawCircle(const Offset(35, 35), 4.8, white);
      canvas.drawCircle(const Offset(20, 35), 2.4, ink);
      canvas.drawCircle(const Offset(35, 35), 2.4, ink);
      canvas.drawCircle(const Offset(27, 47), 5, dark);
    } else if (happy) {
      final pen = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: const Offset(20, 36), width: 11, height: 8), 0, math.pi, false, pen);
      canvas.drawArc(Rect.fromCenter(center: const Offset(35, 36), width: 11, height: 8), 0, math.pi, false, pen);
      canvas.drawOval(Rect.fromCenter(center: const Offset(27, 48), width: 19, height: 13), dark);
      canvas.drawRect(const Rect.fromLTWH(20, 43, 14, 4), white);
      if (tongue) canvas.drawOval(Rect.fromCenter(center: const Offset(27, 52), width: 10, height: 5), Paint()..color = const Color(0xFFFF8CA0));
    } else {
      canvas.drawCircle(const Offset(20, 36), 2.8, ink);
      canvas.drawCircle(const Offset(35, 36), 2.8, ink);
      final smile = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 2.8..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: const Offset(27, 47), width: 16, height: 10), .1, math.pi - .2, false, smile);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMotiPainter oldDelegate) => oldDelegate.happy != happy || oldDelegate.surprised != surprised || oldDelegate.tongue != tongue;
}
