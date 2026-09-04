import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _motiRed = Color(0xFFF04432);
const _motiRedDark = Color(0xFFC92F22);

enum MissionKind { breathe, note, timer, counter, simple }

MissionKind missionKindFor(String mood, int index) {
  switch (mood) {
    case 'Feliz':
      return [MissionKind.note, MissionKind.simple, MissionKind.timer][index];
    case 'Tranquilo':
      return [MissionKind.breathe, MissionKind.simple, MissionKind.counter][index];
    case 'Normal':
      return [MissionKind.timer, MissionKind.simple, MissionKind.simple][index];
    case 'Triste':
      return [MissionKind.breathe, MissionKind.note, MissionKind.simple][index];
    case 'Ansioso':
      return [MissionKind.breathe, MissionKind.counter, MissionKind.timer][index];
    case 'Cansado':
      return [MissionKind.timer, MissionKind.counter, MissionKind.note][index];
    case 'Enojado':
      return [MissionKind.counter, MissionKind.timer, MissionKind.note][index];
    default:
      return MissionKind.simple;
  }
}

int missionSecondsFor(String mood, int index) {
  if (mood == 'Enojado' && index == 1) return 5;
  if (mood == 'Feliz' && index == 2) return 20;
  return 30;
}

int missionTargetFor(String mood, int index) => 3;

String missionPromptFor(String mood) {
  if (mood == 'Feliz') return 'Hoy quiero recordar...';
  if (mood == 'Triste') return 'Ahora mismo necesito...';
  if (mood == 'Cansado') return 'Esto puede esperar hasta mañana...';
  if (mood == 'Enojado') return 'Lo que me molestó fue...';
  return 'Escribe una frase...';
}

class MissionHubCard extends StatelessWidget {
  const MissionHubCard({
    super.key,
    required this.emotion,
    required this.missions,
    required this.selectedIndex,
    required this.done,
    required this.switchUsed,
    required this.enabled,
    required this.onChoose,
    required this.onStart,
    required this.onChange,
  });

  final String? emotion;
  final List<String> missions;
  final int selectedIndex;
  final bool done;
  final bool switchUsed;
  final bool enabled;
  final Future<void> Function(int) onChoose;
  final Future<void> Function() onStart;
  final Future<void> Function() onChange;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex >= 0 && selectedIndex < missions.length ? missions[selectedIndex] : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFEAF7E9) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: done ? const Color(0xFFB8DEB5) : const Color(0xFFF0DDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(done ? '✅' : '✨', style: const TextStyle(fontSize: 25)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(done ? 'Misión completada' : 'Moti te propone', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(
                      enabled ? (done ? 'Hoy ya cumpliste tu pequeño paso.' : 'Elige una para tu estado ${emotion ?? ''}.') : 'Primero registra cómo te sientes.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF82736E)),
                    ),
                  ],
                ),
              ),
              if (done) const Text('+10 ⭐', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4D8E4B))),
            ],
          ),
          if (enabled && !done && selected == null) ...[
            const SizedBox(height: 13),
            ...List.generate(missions.length, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => onChoose(index),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F3),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0xFFFFD8CB)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: const Color(0xFFFFE5DC),
                            child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: _motiRedDark)),
                          ),
                          const SizedBox(width: 11),
                          Expanded(child: Text(missions[index], style: const TextStyle(height: 1.3, fontWeight: FontWeight.w700))),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _motiRedDark),
                        ],
                      ),
                    ),
                  ),
                )),
          ] else if (enabled && selected != null) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: done ? const Color(0xFFF1FAF0) : const Color(0xFFFFF0E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(selected, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35)),
            ),
            if (!done) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Empezar misión'),
                ),
              ),
              if (!switchUsed)
                Center(
                  child: TextButton.icon(
                    onPressed: onChange,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Cambiar misión · 1 vez'),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: Text('Ya usaste el cambio de misión de hoy.', style: TextStyle(fontSize: 11.5, color: Color(0xFF968680)))),
                ),
            ],
          ] else if (!enabled) ...[
            const SizedBox(height: 12),
            const Text('🔒 Las opciones aparecerán cuando registres tu emoción.', style: TextStyle(color: Color(0xFF8C7D78))),
          ],
        ],
      ),
    );
  }
}

class MissionActivityDialog extends StatefulWidget {
  const MissionActivityDialog({
    super.key,
    required this.title,
    required this.moodLabel,
    required this.moodEmoji,
    required this.kind,
    required this.seconds,
    required this.target,
    required this.prompt,
    required this.hapticOn,
  });

  final String title;
  final String moodLabel;
  final String moodEmoji;
  final MissionKind kind;
  final int seconds;
  final int target;
  final String prompt;
  final bool hapticOn;

  @override
  State<MissionActivityDialog> createState() => _MissionActivityDialogState();
}

class _MissionActivityDialogState extends State<MissionActivityDialog> {
  final _text = TextEditingController();
  Timer? _timer;
  int _remaining = 0;
  int _count = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  bool get _ready {
    switch (widget.kind) {
      case MissionKind.note:
        return _text.text.trim().isNotEmpty;
      case MissionKind.timer:
        return _started && _remaining == 0;
      case MissionKind.counter:
        return _count >= widget.target;
      case MissionKind.simple:
        return true;
      case MissionKind.breathe:
        return false;
    }
  }

  void _startTimer() {
    if (_started) return;
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        if (widget.hapticOn) HapticFeedback.mediumImpact();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _tapCounter() {
    if (_count >= widget.target) return;
    if (widget.hapticOn) HapticFeedback.lightImpact();
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      content: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.moodEmoji, style: const TextStyle(fontSize: 55)),
            const SizedBox(height: 6),
            Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.3)),
            const SizedBox(height: 14),
            if (widget.kind == MissionKind.note)
              TextField(
                controller: _text,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.prompt,
                  filled: true,
                  fillColor: const Color(0xFFFFF8F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                ),
              )
            else if (widget.kind == MissionKind.timer) ...[
              Text('$_remaining s', style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              LinearProgressIndicator(
                value: widget.seconds <= 0 ? 1 : 1 - (_remaining / widget.seconds),
                minHeight: 9,
                borderRadius: BorderRadius.circular(9),
              ),
              const SizedBox(height: 12),
              if (!_started)
                FilledButton.icon(onPressed: _startTimer, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Empezar'))
              else if (_remaining > 0)
                const Text('Quédate aquí con Moti...', style: TextStyle(color: Color(0xFF756762)))
              else
                const Text('✅ Listo', style: TextStyle(fontWeight: FontWeight.w900)),
            ] else if (widget.kind == MissionKind.counter) ...[
              Text('$_count / ${widget.target}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                widget.moodLabel == 'Ansioso' ? 'Toca una vez por cada cosa que identifiques a tu alrededor.' : 'Toca después de cada repetición.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF756762)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _count >= widget.target ? null : _tapCounter,
                icon: const Icon(Icons.touch_app_rounded),
                label: Text(_count >= widget.target ? 'Completado' : 'Hecho · sumar 1'),
              ),
            ] else
              const Text(
                'Hazlo a tu ritmo. Cuando termines, marca la actividad como completada.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4, color: Color(0xFF756762)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cerrar')),
        FilledButton(
          onPressed: _ready ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: _motiRed),
          child: const Text('Completar'),
        ),
      ],
    );
  }
}
