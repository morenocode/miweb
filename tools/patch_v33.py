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
    "import 'dynamic_missions.dart';\n",
    "import 'dynamic_missions.dart';\nimport 'moti_minute.dart';\n",
    'import',
)

rep(
    "  bool _missionSwitchUsed = false;\n",
    "  bool _missionSwitchUsed = false;\n  String _motiMinuteDate = '';\n",
    'state',
)

rep(
    "  bool get _moodLockedToday => _logs.any((entry) => entry.date == _today);\n",
    "  bool get _moodLockedToday => _logs.any((entry) => entry.date == _today);\n  bool get _motiMinuteDone => _motiMinuteDate == _today;\n",
    'getter',
)

rep(
    "      _missionSwitchUsed = missionDate == _today ? (prefs.getBool('missionSwitchUsed') ?? false) : false;\n",
    "      _missionSwitchUsed = missionDate == _today ? (prefs.getBool('missionSwitchUsed') ?? false) : false;\n      _motiMinuteDate = prefs.getString('motiMinuteDate') ?? '';\n",
    'load',
)

rep(
    "    await prefs.setBool('missionSwitchUsed', _missionSwitchUsed);\n",
    "    await prefs.setBool('missionSwitchUsed', _missionSwitchUsed);\n    await prefs.setString('motiMinuteDate', _motiMinuteDate);\n",
    'persist',
)

rep(
    "  Future<void> _showMissionCelebration() async {\n",
    """  Future<void> _openMotiMinute() async {\n    final mood = _selected;\n    if (!_missionDone || mood == null) return;\n    final completed = await Navigator.of(context).push<bool>(\n      MaterialPageRoute(\n        builder: (_) => MotiMinutePage(\n          moodLabel: mood.label,\n          moodEmoji: mood.emoji,\n          soundOn: _soundOn,\n          hapticOn: _hapticOn,\n        ),\n      ),\n    );\n    if (completed == true && !_motiMinuteDone) {\n      if (_hapticOn) await HapticFeedback.heavyImpact();\n      setState(() {\n        _motiMinuteDate = _today;\n        _stars += 5;\n        _reactionTick++;\n      });\n      await _persist();\n    }\n  }\n\n  Future<void> _showMissionCelebration() async {\n""",
    'method',
)

rep(
    "            Text('Ese pequeño paso también cuenta.', textAlign: TextAlign.center),\n",
    "            Text('Ese pequeño paso también cuenta. Ahora se desbloqueó 1 minuto con Moti.', textAlign: TextAlign.center),\n",
    'celebration',
)

rep(
    "      _missionSwitchUsed = false;\n    });\n  }\n\n  @override\n  Widget build(BuildContext context) {\n",
    "      _missionSwitchUsed = false;\n      _motiMinuteDate = '';\n    });\n  }\n\n  @override\n  Widget build(BuildContext context) {\n",
    'reset',
)

rep(
    "        missionSwitchUsed: _missionSwitchUsed,\n        moodLocked: _moodLockedToday,\n",
    "        missionSwitchUsed: _missionSwitchUsed,\n        motiMinuteDone: _motiMinuteDone,\n        moodLocked: _moodLockedToday,\n",
    'home args 1',
)

rep(
    "        onMissionChange: _changeMission,\n        onBreathe: _openBreathing,\n",
    "        onMissionChange: _changeMission,\n        onMotiMinute: _openMotiMinute,\n        onBreathe: _openBreathing,\n",
    'home args 2',
)

rep(
    "    required this.missionSwitchUsed,\n    required this.moodLocked,\n",
    "    required this.missionSwitchUsed,\n    required this.motiMinuteDone,\n    required this.moodLocked,\n",
    'constructor 1',
)

rep(
    "    required this.onMissionChange,\n    required this.onBreathe,\n",
    "    required this.onMissionChange,\n    required this.onMotiMinute,\n    required this.onBreathe,\n",
    'constructor 2',
)

rep(
    "  final bool missionSwitchUsed;\n  final bool moodLocked;\n",
    "  final bool missionSwitchUsed;\n  final bool motiMinuteDone;\n  final bool moodLocked;\n",
    'field 1',
)

rep(
    "  final Future<void> Function() onMissionChange;\n  final Future<void> Function() onBreathe;\n",
    "  final Future<void> Function() onMissionChange;\n  final Future<void> Function() onMotiMinute;\n  final Future<void> Function() onBreathe;\n",
    'field 2',
)

mission_sliver = """        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),\n            child: MissionHubCard(\n              emotion: selected?.label,\n              missions: missionOptions,\n              selectedIndex: missionChoice,\n              done: missionDone,\n              switchUsed: missionSwitchUsed,\n              enabled: selected != null,\n              onChoose: onMissionChoice,\n              onStart: onMissionStart,\n              onChange: onMissionChange,\n            ),\n          ),\n        ),\n"""
minute_sliver = mission_sliver + """        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),\n            child: MotiMinuteCard(\n              unlocked: missionDone,\n              done: motiMinuteDone,\n              moodLabel: selected?.label,\n              onStart: onMotiMinute,\n            ),\n          ),\n        ),\n"""
rep(mission_sliver, minute_sliver, 'minute card')

p.write_text(s, encoding='utf-8')
print(f'Patched {p} to v3.3')
