from pathlib import Path
import sys

p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')

def once(old,new,label):
    global s
    if old not in s:
        raise SystemExit(label+' marker not found')
    s=s.replace(old,new,1)

once("import 'moti_minute.dart';\n","import 'moti_minute.dart';\nimport 'moti_bubbles_game.dart';\n",'import')
once("  String _motiMinuteDate = '';\n","  String _motiMinuteDate = '';\n  String _bubbleGameDate = '';\n",'state')
once("  bool get _motiMinuteDone => _motiMinuteDate == _today;\n","  bool get _motiMinuteDone => _motiMinuteDate == _today;\n  bool get _bubbleGameDone => _bubbleGameDate == _today;\n",'getter')
once("      _motiMinuteDate = prefs.getString('motiMinuteDate') ?? '';\n","      _motiMinuteDate = prefs.getString('motiMinuteDate') ?? '';\n      _bubbleGameDate = prefs.getString('bubbleGameDate') ?? '';\n",'load')
once("    await prefs.setString('motiMinuteDate', _motiMinuteDate);\n","    await prefs.setString('motiMinuteDate', _motiMinuteDate);\n    await prefs.setString('bubbleGameDate', _bubbleGameDate);\n",'persist')
once("  Future<void> _openMotiMinute() async {\n","  Future<void> _openBubbleGame() async {\n    final won = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => BubbleMathGamePage(soundOn: _soundOn, hapticOn: _hapticOn)));\n    if (won == true && !_bubbleGameDone) {\n      if (_hapticOn) await HapticFeedback.heavyImpact();\n      setState(() { _bubbleGameDate = _today; _stars += 10; _reactionTick++; });\n      await _persist();\n    }\n  }\n\n  Future<void> _openMotiMinute() async {\n",'method')
once("      _motiMinuteDate = '';\n    });\n  }\n\n  @override\n  Widget build(BuildContext context) {\n","      _motiMinuteDate = '';\n      _bubbleGameDate = '';\n    });\n  }\n\n  @override\n  Widget build(BuildContext context) {\n",'reset')
once("        motiMinuteDone: _motiMinuteDone,\n        moodLocked: _moodLockedToday,\n","        motiMinuteDone: _motiMinuteDone,\n        bubbleGameDone: _bubbleGameDone,\n        moodLocked: _moodLockedToday,\n",'arg1')
once("        onMotiMinute: _openMotiMinute,\n        onBreathe: _openBreathing,\n","        onMotiMinute: _openMotiMinute,\n        onBubbleGame: _openBubbleGame,\n        onBreathe: _openBreathing,\n",'arg2')
once("    required this.motiMinuteDone,\n    required this.moodLocked,\n","    required this.motiMinuteDone,\n    required this.bubbleGameDone,\n    required this.moodLocked,\n",'ctor1')
once("    required this.onMotiMinute,\n    required this.onBreathe,\n","    required this.onMotiMinute,\n    required this.onBubbleGame,\n    required this.onBreathe,\n",'ctor2')
once("  final bool motiMinuteDone;\n  final bool moodLocked;\n","  final bool motiMinuteDone;\n  final bool bubbleGameDone;\n  final bool moodLocked;\n",'field1')
once("  final Future<void> Function() onMotiMinute;\n  final Future<void> Function() onBreathe;\n","  final Future<void> Function() onMotiMinute;\n  final Future<void> Function() onBubbleGame;\n  final Future<void> Function() onBreathe;\n",'field2')
needle="""        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: MotiMinuteCard(
              unlocked: missionDone,
              done: motiMinuteDone,
              moodLabel: selected?.label,
              onStart: onMotiMinute,
            ),
          ),
        ),
"""
insert=needle+"""        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: MotiGameCard(doneToday: bubbleGameDone, onStart: onBubbleGame),
          ),
        ),
"""
once(needle,insert,'card')
p.write_text(s,encoding='utf-8')
print('Patched v3.4')
