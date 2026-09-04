from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text(encoding='utf-8')

s = s.replace(
    "import 'package:shared_preferences/shared_preferences.dart';\n",
    "import 'package:shared_preferences/shared_preferences.dart';\n\nimport 'dynamic_missions.dart';\n",
    1,
)

s = s.replace(
    "  int _reactionTick = 0;\n",
    "  int _reactionTick = 0;\n  int _missionChoice = -1;\n  bool _missionSwitchUsed = false;\n",
    1,
)

s = s.replace(
    "  bool get _moodLockedToday => _logs.any((entry) => entry.date == _today);\n",
    """  bool get _moodLockedToday => _logs.any((entry) => entry.date == _today);\n\n  List<String> get _missionOptions => _selected?.actions ?? const [];\n\n  String? get _chosenMission {\n    final options = _missionOptions;\n    if (_missionChoice < 0 || _missionChoice >= options.length) return null;\n    return options[_missionChoice];\n  }\n""",
    1,
)

s = s.replace(
    "      _logs = loadedLogs;\n      _selected = todayMood;\n",
    """      _logs = loadedLogs;\n      _selected = todayMood;\n      _missionChoice = missionDate == _today ? (prefs.getInt('missionChoice') ?? -1) : -1;\n      _missionSwitchUsed = missionDate == _today ? (prefs.getBool('missionSwitchUsed') ?? false) : false;\n""",
    1,
)

s = s.replace(
    "    await prefs.setString('breathingRewardDate', _breathingRewardDate);\n",
    """    await prefs.setString('breathingRewardDate', _breathingRewardDate);\n    await prefs.setInt('missionChoice', _missionChoice);\n    await prefs.setBool('missionSwitchUsed', _missionSwitchUsed);\n""",
    1,
)

s = s.replace(
    "      _missionDone = false;\n      _missionDate = '';\n      _reactionTick++;\n",
    """      _missionDone = false;\n      _missionDate = '';\n      _missionChoice = -1;\n      _missionSwitchUsed = false;\n      _reactionTick++;\n""",
    1,
)

marker = "  void _newMessage() {\n"
methods = """  Future<void> _chooseMission(int index) async {\n    final options = _missionOptions;\n    if (_missionDone || index < 0 || index >= options.length) return;\n    if (_hapticOn) await HapticFeedback.selectionClick();\n    setState(() {\n      _missionChoice = index;\n      _missionDate = _today;\n    });\n    await _persist();\n  }\n\n  Future<void> _changeMission() async {\n    if (_missionDone || _missionSwitchUsed) return;\n    if (_hapticOn) await HapticFeedback.selectionClick();\n    setState(() {\n      _missionChoice = -1;\n      _missionSwitchUsed = true;\n      _missionDate = _today;\n    });\n    await _persist();\n  }\n\n  Future<void> _startChosenMission() async {\n    final mood = _selected;\n    final mission = _chosenMission;\n    if (mood == null || mission == null || _missionDone) return;\n    final kind = missionKindFor(mood.label, _missionChoice);\n\n    bool completed = false;\n    if (kind == MissionKind.breathe) {\n      completed = await Navigator.of(context).push<bool>(\n            MaterialPageRoute(\n              builder: (_) => BreathingPage(soundOn: _soundOn, hapticOn: _hapticOn),\n            ),\n          ) ??\n          false;\n    } else {\n      completed = await showDialog<bool>(\n            context: context,\n            barrierDismissible: false,\n            builder: (_) => MissionActivityDialog(\n              title: mission,\n              moodLabel: mood.label,\n              moodEmoji: mood.emoji,\n              kind: kind,\n              seconds: missionSecondsFor(mood.label, _missionChoice),\n              target: missionTargetFor(mood.label, _missionChoice),\n              prompt: missionPromptFor(mood.label),\n              hapticOn: _hapticOn,\n            ),\n          ) ??\n          false;\n    }\n\n    if (completed) await _completeMission();\n  }\n\n  Future<void> _showMissionCelebration() async {\n    if (!mounted) return;\n    await showDialog<void>(\n      context: context,\n      builder: (dialogContext) => AlertDialog(\n        content: const Column(\n          mainAxisSize: MainAxisSize.min,\n          children: [\n            Moti(face: MotiFace.happy, size: 130),\n            SizedBox(height: 6),\n            Text('¡Misión cumplida!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),\n            SizedBox(height: 6),\n            Text('+10 ⭐', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: motiRedDark)),\n            SizedBox(height: 5),\n            Text('Ese pequeño paso también cuenta.', textAlign: TextAlign.center),\n          ],\n        ),\n        actions: [\n          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Seguir')),\n        ],\n      ),\n    );\n  }\n\n"""
if marker not in s:
    raise SystemExit('newMessage marker not found')
s = s.replace(marker, methods + marker, 1)

old_complete = """  Future<void> _completeMission() async {\n    if (_missionDone) return;\n    if (_hapticOn) await HapticFeedback.mediumImpact();\n    setState(() {\n      _missionDone = true;\n      _missionDate = _today;\n      _stars += 10;\n    });\n    await _persist();\n  }\n"""
new_complete = """  Future<void> _completeMission() async {\n    if (_missionDone) return;\n    if (_hapticOn) await HapticFeedback.mediumImpact();\n    setState(() {\n      _missionDone = true;\n      _missionDate = _today;\n      _stars += 10;\n      _reactionTick++;\n    });\n    await _persist();\n    await _showMissionCelebration();\n  }\n"""
if old_complete not in s:
    raise SystemExit('completeMission block not found')
s = s.replace(old_complete, new_complete, 1)

s = s.replace(
    "      _reactionTick = 0;\n    });\n",
    "      _reactionTick = 0;\n      _missionChoice = -1;\n      _missionSwitchUsed = false;\n    });\n",
    1,
)

s = s.replace(
    """        mission: _todayMission,\n        missionDone: _missionDone,\n        moodLocked: _moodLockedToday,\n        reactionTick: _reactionTick,\n        onMood: _chooseMood,\n        onNewMessage: _newMessage,\n        onMissionDone: _completeMission,\n        onBreathe: _openBreathing,\n""",
    """        missionOptions: _missionOptions,\n        missionChoice: _missionChoice,\n        missionDone: _missionDone,\n        missionSwitchUsed: _missionSwitchUsed,\n        moodLocked: _moodLockedToday,\n        reactionTick: _reactionTick,\n        onMood: _chooseMood,\n        onNewMessage: _newMessage,\n        onMissionChoice: _chooseMission,\n        onMissionStart: _startChosenMission,\n        onMissionChange: _changeMission,\n        onBreathe: _openBreathing,\n""",
    1,
)

s = s.replace(
    """    required this.mission,\n    required this.missionDone,\n    required this.moodLocked,\n    required this.reactionTick,\n    required this.onMood,\n    required this.onNewMessage,\n    required this.onMissionDone,\n    required this.onBreathe,\n""",
    """    required this.missionOptions,\n    required this.missionChoice,\n    required this.missionDone,\n    required this.missionSwitchUsed,\n    required this.moodLocked,\n    required this.reactionTick,\n    required this.onMood,\n    required this.onNewMessage,\n    required this.onMissionChoice,\n    required this.onMissionStart,\n    required this.onMissionChange,\n    required this.onBreathe,\n""",
    1,
)

s = s.replace(
    """  final String mission;\n  final bool missionDone;\n  final bool moodLocked;\n  final int reactionTick;\n  final Future<void> Function(Mood) onMood;\n  final VoidCallback onNewMessage;\n  final Future<void> Function() onMissionDone;\n  final Future<void> Function() onBreathe;\n""",
    """  final List<String> missionOptions;\n  final int missionChoice;\n  final bool missionDone;\n  final bool missionSwitchUsed;\n  final bool moodLocked;\n  final int reactionTick;\n  final Future<void> Function(Mood) onMood;\n  final VoidCallback onNewMessage;\n  final Future<void> Function(int) onMissionChoice;\n  final Future<void> Function() onMissionStart;\n  final Future<void> Function() onMissionChange;\n  final Future<void> Function() onBreathe;\n""",
    1,
)

old_card = "            child: _MissionCard(mission: mission, emotion: selected?.label, done: missionDone, enabled: selected != null, onDone: onMissionDone),"
new_card = """            child: MissionHubCard(\n              emotion: selected?.label,\n              missions: missionOptions,\n              selectedIndex: missionChoice,\n              done: missionDone,\n              switchUsed: missionSwitchUsed,\n              enabled: selected != null,\n              onChoose: onMissionChoice,\n              onStart: onMissionStart,\n              onChange: onMissionChange,\n            ),"""
if old_card not in s:
    raise SystemExit('mission card use not found')
s = s.replace(old_card, new_card, 1)

p.write_text(s, encoding='utf-8')
