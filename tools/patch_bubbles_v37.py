from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')

start = s.index('  @override\n  Widget build(BuildContext context) {', s.index('class _BubbleMathGamePageState'))
end = s.index('\n}\n\nclass _QuestionClock', start) + 2

new_build = r"""  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Burbujas de Moti', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxHeight < 640;
            final outer = compact ? 10.0 : 14.0;
            final verticalGap = compact ? 7.0 : 10.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(outer, compact ? 6 : 10, outer, compact ? 9 : 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _Pill(icon: '⏱️', text: '${_remaining}s')),
                      const SizedBox(width: 7),
                      Expanded(child: _Pill(icon: '✅', text: '$_correct  ❌ $_wrong')),
                      const SizedBox(width: 7),
                      Expanded(child: _Pill(icon: '🪜', text: '${math.max(0, _step)}/$_goal')),
                    ],
                  ),
                  SizedBox(height: verticalGap),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: compact ? 10 : 13, horizontal: compact ? 12 : 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _started && !_finished && _questionRemaining <= 3
                            ? const [Color(0xFFFFE1D8), Color(0xFFFFF2EC)]
                            : const [Color(0xFFFFEEE7), Color(0xFFFFF8F4)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _started && !_finished && _questionRemaining <= 3 ? _red.withValues(alpha: .65) : const Color(0xFFF3D9CF),
                        width: _started && !_finished && _questionRemaining <= 3 ? 2 : 1,
                      ),
                      boxShadow: _started && !_finished && _questionRemaining <= 2
                          ? [BoxShadow(color: _red.withValues(alpha: .14), blurRadius: 14, spreadRadius: 1)]
                          : const [],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _started && !_finished && _questionRemaining <= 3 ? '⚠️ ¡RÁPIDO, MOTI ESTÁ NERVIOSO!' : '🧠 RESUELVE ESTA OPERACIÓN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 10.4 : 11.3,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .1,
                                  color: _started && !_finished && _questionRemaining <= 3 ? _redDark : const Color(0xFF8B6F66),
                                ),
                              ),
                              SizedBox(height: compact ? 2 : 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(_question, style: TextStyle(fontSize: compact ? 29 : 33, fontWeight: FontWeight.w900, color: _ink)),
                              ),
                              SizedBox(height: compact ? 2 : 4),
                              Text(
                                _started && !_finished
                                    ? (_questionRemaining <= 1 ? '¡Último segundo! El escalón puede quebrarse.' : 'Revienta la respuesta antes de la alarma.')
                                    : 'Toca la burbuja con la respuesta correcta.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: compact ? 10.2 : 11.2, height: 1.2, color: const Color(0xFF7D6963)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuestionClock(
                          remaining: _questionRemaining,
                          limit: _questionLimit,
                          active: _started && !_finished,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: verticalGap),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 7 : 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF0DDD6)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: compact ? 108 : 118,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: EdgeInsets.fromLTRB(compact ? 5 : 7, 5, compact ? 5 : 7, 9),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFFFF2EC), Color(0xFFFFFAF7)],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text('MOTI', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .8, color: _redDark)),
                                    const SizedBox(height: 3),
                                    Expanded(
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
                                            falling: _falling,
                                            gameOver: _gameOver,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFF8FCFF), Color(0xFFFFFBF0)],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 7, bottom: 2),
                                      child: Text('REVIENTA UNA BURBUJA', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .55, color: Color(0xFF74645F))),
                                    ),
                                    Expanded(
                                      child: AnimatedBuilder(
                                        animation: _float,
                                        builder: (context, _) {
                                          return LayoutBuilder(
                                            builder: (context, box) {
                                              final bubbleSize = compact ? 68.0 : 74.0;
                                              final cellW = box.maxWidth / 2;
                                              final cellH = box.maxHeight / 2;
                                              return Stack(
                                                clipBehavior: Clip.hardEdge,
                                                children: List.generate(_options.length, (index) {
                                                  final col = index % 2;
                                                  final row = index ~/ 2;
                                                  final driftX = math.cos((_float.value * math.pi * 2) + index * .9) * 3.0;
                                                  final driftY = math.sin((_float.value * math.pi * 2) + index * 1.4) * 6.0;
                                                  final rawLeft = col * cellW + (cellW - bubbleSize) / 2 + driftX;
                                                  final rawTop = row * cellH + (cellH - bubbleSize) / 2 + driftY;
                                                  final maxLeft = math.max(4.0, box.maxWidth - bubbleSize - 4);
                                                  final maxTop = math.max(4.0, box.maxHeight - bubbleSize - 4);
                                                  final left = rawLeft.clamp(4.0, maxLeft).toDouble();
                                                  final top = rawTop.clamp(4.0, maxTop).toDouble();
                                                  final popped = _popped.contains(index);
                                                  return Positioned(
                                                    left: left,
                                                    top: top,
                                                    child: AnimatedScale(
                                                      duration: const Duration(milliseconds: 170),
                                                      scale: popped ? 0.05 : 1,
                                                      child: AnimatedOpacity(
                                                        duration: const Duration(milliseconds: 150),
                                                        opacity: popped ? 0 : 1,
                                                        child: _AnswerBubble(
                                                          value: _options[index],
                                                          index: index,
                                                          enabled: _started && !_finished && !_transitioning,
                                                          onTap: () => _tapBubble(index),
                                                          size: bubbleSize,
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 9),
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
                      _gameOver
                          ? '🕳️ ¡Moti cayó al vacío! Game Over'
                          : (_won ? '🏆 ¡Moti llegó a la meta!' : '⏰ Se acabó el minuto. Llegaste al escalón ${math.max(0, _step)}.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: compact ? 16 : 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _retry, child: const Text('Reintentar'))),
                        const SizedBox(width: 9),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, _won),
                            child: Text(_won ? 'Volver · +10 ⭐' : 'Volver'),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 5 : 7),
                      decoration: BoxDecoration(color: const Color(0xFFFFF5F1), borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        _transitioning
                            ? '💥 ¡El escalón se rompió! Moti está cayendo…'
                            : '✅ Acierto: subes   •   ❌ Fallo/tiempo: bajas   •   🕳️ Desde el primero: Game Over',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: compact ? 10.2 : 11.2, color: const Color(0xFF8B7B76), fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}"""

s = s[:start] + new_build + s[end:]
s = s.replace('        width: 82,\n        height: 82,\n        padding: const EdgeInsets.all(7),', '        width: 72,\n        height: 72,\n        padding: const EdgeInsets.all(6),', 1)
s = s.replace('Icon(critical ? Icons.alarm_on_rounded : Icons.timer_rounded, size: 17', 'Icon(critical ? Icons.alarm_on_rounded : Icons.timer_rounded, size: 15', 1)
s = s.replace("Text('$remaining', style: TextStyle(fontSize: 22", "Text('$remaining', style: TextStyle(fontSize: 20", 1)

old_pill = """    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF1DDD6))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon), const SizedBox(width: 5), Text(text, style: const TextStyle(fontWeight: FontWeight.w900))]),
    );"""
new_pill = """    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1DDD6))),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon), const SizedBox(width: 4), Text(text, style: const TextStyle(fontWeight: FontWeight.w900))]),
      ),
    );"""
if old_pill not in s:
    raise SystemExit('pill block not found')
s = s.replace(old_pill, new_pill, 1)

s = s.replace('const _AnswerBubble({required this.value, required this.index, required this.enabled, required this.onTap});', 'const _AnswerBubble({required this.value, required this.index, required this.enabled, required this.onTap, this.size = 74});', 1)
needle = '  final VoidCallback onTap;\n'
pos = s.index(needle, s.index('class _AnswerBubble'))
s = s[:pos] + needle + '  final double size;\n' + s[pos + len(needle):]
s = s.replace('        width: 86,\n        height: 86,', '        width: size,\n        height: size,', 1)
s = s.replace("            const Positioned(top: 13, left: 17, child: CircleAvatar(radius: 7, backgroundColor: Colors.white70)),\n            Center(child: Text('$value', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _ink))),", "            Positioned(top: size * .15, left: size * .20, child: CircleAvatar(radius: size * .075, backgroundColor: Colors.white70)),\n            Center(child: Text('$value', style: TextStyle(fontSize: size * .29, fontWeight: FontWeight.w900, color: _ink))),", 1)

p.write_text(s, encoding='utf-8')
print('v3.7 responsive layout applied')