from pathlib import Path
import re, sys

p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')

s = re.sub(r"\nconst dailyMissions = <String>\[.*?\n\];\n", "\n", s, flags=re.S)
s = s.replace("  List<MoodLog> _logs = [];\n", "  List<MoodLog> _logs = [];\n  int _reactionTick = 0;\n")

s = re.sub(
    r"  String get _todayMission \{.*?\n  \}\n",
    """  String get _todayMission {\n    final mood = _selected;\n    if (mood == null) {\n      return 'Primero registra cómo te sientes para que Moti elija tu misión.';\n    }\n    final now = DateTime.now();\n    final moodIndex = moodItems.indexOf(mood);\n    final index = (now.year + now.month * 31 + now.day + moodIndex * 7) % mood.actions.length;\n    return mood.actions[index];\n  }\n\n  bool get _moodLockedToday => _logs.any((entry) => entry.date == _today);\n""",
    s,
    count=1,
    flags=re.S,
)

old = """    if (!mounted) return;\n    setState(() {\n      _stars = prefs.getInt('stars') ?? 0;\n      _streak = streak;\n      _lastLogDate = lastDate;\n      _missionDate = missionDate;\n      _missionDone = missionDone;\n      _soundOn = prefs.getBool('soundOn') ?? true;\n      _hapticOn = prefs.getBool('hapticOn') ?? true;\n      _breathingRewardDate = prefs.getString('breathingRewardDate') ?? '';\n      _logs = loadedLogs;\n      _loading = false;\n    });\n"""
new = """    Mood? todayMood;\n    for (final log in loadedLogs) {\n      if (log.date == _today) {\n        for (final mood in moodItems) {\n          if (mood.label == log.label) {\n            todayMood = mood;\n            break;\n          }\n        }\n        break;\n      }\n    }\n\n    if (!mounted) return;\n    setState(() {\n      _stars = prefs.getInt('stars') ?? 0;\n      _streak = streak;\n      _lastLogDate = lastDate;\n      _missionDate = missionDate;\n      _missionDone = missionDone;\n      _soundOn = prefs.getBool('soundOn') ?? true;\n      _hapticOn = prefs.getBool('hapticOn') ?? true;\n      _breathingRewardDate = prefs.getString('breathingRewardDate') ?? '';\n      _logs = loadedLogs;\n      _selected = todayMood;\n      if (todayMood != null) {\n        _message = todayMood.messages.first;\n        _action = todayMood.actions[(todayMood.actions.length > 1) ? 1 : 0];\n      }\n      _loading = false;\n    });\n"""
if old not in s:
    raise SystemExit('loadData block not found')
s = s.replace(old, new)

pattern = r"  Future<void> _chooseMood\(Mood mood\) async \{.*?\n  \}\n\n  void _newMessage\(\)"
replacement = """  Future<void> _chooseMood(Mood mood) async {\n    final todayIndex = _logs.indexWhere((entry) => entry.date == _today);\n    if (todayIndex >= 0) {\n      final existing = _logs[todayIndex];\n      if (existing.label != mood.label) {\n        if (_hapticOn) await HapticFeedback.selectionClick();\n        return;\n      }\n      if (_hapticOn) await HapticFeedback.lightImpact();\n      await _playMoodSound(mood);\n      if (!mounted) return;\n      setState(() => _reactionTick++);\n      return;\n    }\n\n    if (_hapticOn) await HapticFeedback.lightImpact();\n    await _playMoodSound(mood);\n\n    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));\n    final streak = _lastLogDate == yesterday ? max(1, _streak + 1) : 1;\n    final stars = _stars + 5;\n    final log = MoodLog(date: _today, label: mood.label, emoji: mood.emoji);\n    final nextLogs = [log, ..._logs];\n    if (nextLogs.length > 90) nextLogs.removeRange(90, nextLogs.length);\n\n    final mission = _missionFor(mood);\n    final actionOptions = mood.actions.where((item) => item != mission).toList();\n    final nextAction = actionOptions.isEmpty\n        ? mission\n        : actionOptions[_random.nextInt(actionOptions.length)];\n\n    if (!mounted) return;\n    setState(() {\n      _selected = mood;\n      _message = mood.messages[_random.nextInt(mood.messages.length)];\n      _action = nextAction;\n      _stars = stars;\n      _streak = streak;\n      _lastLogDate = _today;\n      _logs = nextLogs;\n      _missionDone = false;\n      _missionDate = '';\n      _reactionTick++;\n    });\n    await _persist();\n  }\n\n  String _missionFor(Mood mood) {\n    final now = DateTime.now();\n    final moodIndex = moodItems.indexOf(mood);\n    final index = (now.year + now.month * 31 + now.day + moodIndex * 7) % mood.actions.length;\n    return mood.actions[index];\n  }\n\n  void _newMessage()"""
s, n = re.subn(pattern, replacement, s, count=1, flags=re.S)
if n != 1:
    raise SystemExit('chooseMood block not found')

s = s.replace(
    "      _message = next;\n      _action = mood.actions[_random.nextInt(mood.actions.length)];\n",
    "      _message = next;\n      final mission = _missionFor(mood);\n      final choices = mood.actions.where((item) => item != mission).toList();\n      _action = choices.isEmpty ? mission : choices[_random.nextInt(choices.length)];\n      _reactionTick++;\n",
)

s = s.replace("      _hapticOn = true;\n    });\n", "      _hapticOn = true;\n      _reactionTick = 0;\n    });\n", 1)

s = s.replace(
    "        missionDone: _missionDone,\n        onMood: _chooseMood,",
    "        missionDone: _missionDone,\n        moodLocked: _moodLockedToday,\n        reactionTick: _reactionTick,\n        onMood: _chooseMood,",
)
s = s.replace(
    "    required this.missionDone,\n    required this.onMood,",
    "    required this.missionDone,\n    required this.moodLocked,\n    required this.reactionTick,\n    required this.onMood,",
)
s = s.replace(
    "  final bool missionDone;\n  final Future<void> Function(Mood) onMood;",
    "  final bool missionDone;\n  final bool moodLocked;\n  final int reactionTick;\n  final Future<void> Function(Mood) onMood;",
)

start_token = "        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),\n            child: Container(\n              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),"
end_token = "        const SliverToBoxAdapter(\n          child: Padding(\n            padding: EdgeInsets.fromLTRB(20, 25, 20, 10),"
start = s.index(start_token)
end = s.index(end_token, start)
hero = """        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),\n            child: Column(\n              children: [\n                Row(\n                  children: [\n                    Container(\n                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),\n                      decoration: BoxDecoration(\n                        color: const Color(0xFFFFE7DF),\n                        borderRadius: BorderRadius.circular(30),\n                      ),\n                      child: const Text('🥭  Moti', style: TextStyle(color: motiRedDark, fontWeight: FontWeight.w900)),\n                    ),\n                    const Spacer(),\n                    if (moodLocked)\n                      const Row(\n                        children: [\n                          Icon(Icons.lock_rounded, size: 15, color: Color(0xFF8D7B75)),\n                          SizedBox(width: 4),\n                          Text('Emoción de hoy', style: TextStyle(color: Color(0xFF8D7B75), fontWeight: FontWeight.w800, fontSize: 12)),\n                        ],\n                      )\n                    else\n                      const Text('Tu compañero', style: TextStyle(color: Color(0xFF8D7B75), fontWeight: FontWeight.w800)),\n                  ],\n                ),\n                const SizedBox(height: 2),\n                MotiMotion(face: face, reactionId: reactionTick, size: 214),\n                const SizedBox(height: 4),\n                AnimatedContainer(\n                  duration: const Duration(milliseconds: 300),\n                  width: double.infinity,\n                  padding: const EdgeInsets.fromLTRB(17, 15, 17, 13),\n                  decoration: BoxDecoration(\n                    color: Colors.white,\n                    borderRadius: BorderRadius.circular(22),\n                    border: Border.all(color: const Color(0xFFF0E5E1)),\n                    boxShadow: [BoxShadow(color: accent.withValues(alpha: .08), blurRadius: 18, offset: const Offset(0, 8))],\n                  ),\n                  child: Column(\n                    children: [\n                      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15.5, height: 1.42, fontWeight: FontWeight.w800, color: Color(0xFF392D2A))),\n                      if (selected != null)\n                        TextButton.icon(\n                          onPressed: onNewMessage,\n                          icon: const Icon(Icons.auto_awesome_rounded, size: 17),\n                          label: const Text('Otra frase'),\n                        ),\n                    ],\n                  ),\n                ),\n              ],\n            ),\n          ),\n        ),\n"""
s = s[:start] + hero + s[end:]

s = s.replace(
    """        const SliverToBoxAdapter(\n          child: Padding(\n            padding: EdgeInsets.fromLTRB(20, 25, 20, 10),\n            child: Text('¿Cómo te sientes?', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.3)),\n          ),\n        ),""",
    """        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),\n            child: Row(\n              children: [\n                const Expanded(child: Text('¿Cómo te sientes?', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.3))),\n                if (moodLocked)\n                  const Text('Registrado 🔒', style: TextStyle(fontSize: 12, color: Color(0xFF8D7B75), fontWeight: FontWeight.w800)),\n              ],\n            ),\n          ),\n        ),""",
)

s = s.replace(
    "                return _MoodButton(mood: mood, selected: mood == selected, onTap: () => onMood(mood));",
    """                final isSelected = mood == selected;\n                final disabled = moodLocked && !isSelected;\n                return _MoodButton(\n                  mood: mood,\n                  selected: isSelected,\n                  disabled: disabled,\n                  onTap: disabled ? null : () => onMood(mood),\n                );""",
)

s = s.replace(
    "            child: _MissionCard(mission: mission, done: missionDone, onDone: onMissionDone),",
    "            child: _MissionCard(mission: mission, emotion: selected?.label, done: missionDone, enabled: selected != null, onDone: onMissionDone),",
)
s = s.replace(
    "  const _MissionCard({required this.mission, required this.done, required this.onDone});\n  final String mission;\n  final bool done;\n  final Future<void> Function() onDone;",
    "  const _MissionCard({required this.mission, required this.emotion, required this.done, required this.enabled, required this.onDone});\n  final String mission;\n  final String? emotion;\n  final bool done;\n  final bool enabled;\n  final Future<void> Function() onDone;",
)
s = s.replace("        color: done ? const Color(0xFFEAF7E9) : const Color(0xFFFFF0E9),", "        color: done ? const Color(0xFFEAF7E9) : (enabled ? const Color(0xFFFFF0E9) : const Color(0xFFF4F0EE)),")
s = s.replace("                Text(done ? 'Misión completada' : 'Misión de hoy · +10 ⭐', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),", "                Text(done ? 'Misión completada' : (enabled ? 'Misión para ${emotion ?? ''} · +10 ⭐' : 'Misión de hoy'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),")
s = s.replace("          IconButton.filledTonal(onPressed: done ? null : onDone, icon: Icon(done ? Icons.check_rounded : Icons.arrow_forward_rounded)),", "          IconButton.filledTonal(onPressed: (!enabled || done) ? null : onDone, icon: Icon(done ? Icons.check_rounded : (enabled ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded))),")

s = s.replace(
    "  const _MoodButton({required this.mood, required this.selected, required this.onTap});\n  final Mood mood;\n  final bool selected;\n  final VoidCallback onTap;",
    "  const _MoodButton({required this.mood, required this.selected, required this.disabled, required this.onTap});\n  final Mood mood;\n  final bool selected;\n  final bool disabled;\n  final VoidCallback? onTap;",
)
s = s.replace(
    "    return GestureDetector(\n      onTap: onTap,\n      child: AnimatedContainer(",
    "    return GestureDetector(\n      onTap: onTap,\n      child: AnimatedOpacity(\n        duration: const Duration(milliseconds: 220),\n        opacity: disabled ? .34 : 1,\n        child: AnimatedContainer(",
)
old_end = """          ],\n        ),\n      ),\n    );\n  }\n}\n\nclass _StatPill"""
new_end = """          ],\n        ),\n      ),\n      ),\n    );\n  }\n}\n\nclass _StatPill"""
if old_end not in s:
    raise SystemExit('mood button ending not found')
s = s.replace(old_end, new_end, 1)

s = s.replace(
    """                  child: Container(\n                    width: 230,\n                    height: 230,\n                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFDED4), boxShadow: [BoxShadow(color: motiRed.withValues(alpha: .18), blurRadius: 38, spreadRadius: 6)]),\n                    alignment: Alignment.center,\n                    child: const Moti(face: MotiFace.calm, size: 170),\n                  ),""",
    "                  child: const Moti(face: MotiFace.calm, size: 205),",
)

marker = "class Moti extends StatelessWidget {"
motion = r'''class MotiMotion extends StatefulWidget {
  const MotiMotion({super.key, required this.face, required this.reactionId, this.size = 210});
  final MotiFace face;
  final int reactionId;
  final double size;

  @override
  State<MotiMotion> createState() => _MotiMotionState();
}

class _MotiMotionState extends State<MotiMotion> with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _reaction;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _reaction = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));
  }

  @override
  void didUpdateWidget(covariant MotiMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reactionId != widget.reactionId || oldWidget.face != widget.face) {
      _reaction.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, _reaction]),
      builder: (context, child) {
        final ambientWave = sin(_ambient.value * pi * 2);
        final p = Curves.easeOut.transform(_reaction.value);
        var dx = 0.0;
        var dy = ambientWave * 3.0;
        var rotation = ambientWave * .012;
        var scale = 1.0 + ambientWave * .012;
        final pulse = sin(pi * p);
        final fade = 1 - p;

        switch (widget.face) {
          case MotiFace.happy:
          case MotiFace.excited:
            dy -= pulse * 22;
            scale += pulse * .09;
            rotation += sin(p * pi * 2) * .055 * fade;
            break;
          case MotiFace.calm:
            scale += pulse * .035;
            dy -= pulse * 5;
            break;
          case MotiFace.neutral:
            dy -= pulse * 8;
            scale += pulse * .025;
            break;
          case MotiFace.sad:
            dy += pulse * 11;
            rotation -= pulse * .035;
            scale -= pulse * .025;
            break;
          case MotiFace.anxious:
            dx += sin(p * pi * 10) * 8 * fade;
            rotation += sin(p * pi * 8) * .025 * fade;
            break;
          case MotiFace.sleepy:
            rotation += sin(p * pi * 2) * .075 * fade;
            dy += pulse * 5;
            break;
          case MotiFace.angry:
            dx += sin(p * pi * 12) * 10 * fade;
            rotation += sin(p * pi * 10) * .045 * fade;
            scale += pulse * .045;
            break;
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Moti(face: widget.face, size: widget.size),
    );
  }
}

'''
if marker not in s:
    raise SystemExit('Moti marker missing')
s = s.replace(marker, motion + marker, 1)
p.write_text(s, encoding='utf-8')
print('Patched', p, 'to v3.1')
