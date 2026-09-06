from pathlib import Path
import sys
import base64
import gzip
import subprocess

p = Path(sys.argv[1])
s = p.read_text()

def once(old, new, label):
    global s
    if old not in s:
        raise SystemExit(f'v4 patch anchor not found: {label}')
    s = s.replace(old, new, 1)

once("import 'moti_bubbles_game.dart';\n", "import 'moti_bubbles_game.dart';\nimport 'moti_bridge_game.dart';\n", 'import')
once("  String _bubbleGameDate = '';\n", "  String _bubbleGameDate = '';\n  String _bridgeGameDate = '';\n", 'state')
once("  bool get _bubbleGameDone => _bubbleGameDate == _today;\n", "  bool get _bubbleGameDone => _bubbleGameDate == _today;\n  bool get _bridgeGameDone => _bridgeGameDate == _today;\n", 'getter')
once("      _bubbleGameDate = prefs.getString('bubbleGameDate') ?? '';\n", "      _bubbleGameDate = prefs.getString('bubbleGameDate') ?? '';\n      _bridgeGameDate = prefs.getString('bridgeGameDate') ?? '';\n", 'load')
once("    await prefs.setString('bubbleGameDate', _bubbleGameDate);\n", "    await prefs.setString('bubbleGameDate', _bubbleGameDate);\n    await prefs.setString('bridgeGameDate', _bridgeGameDate);\n", 'persist')

bubble_method = """  Future<void> _openBubbleGame() async {\n    final won = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => BubbleMathGamePage(soundOn: _soundOn, hapticOn: _hapticOn)));\n    if (won == true && !_bubbleGameDone) {\n      if (_hapticOn) await HapticFeedback.heavyImpact();\n      setState(() { _bubbleGameDate = _today; _stars += 10; _reactionTick++; });\n      await _persist();\n    }\n  }\n"""
bridge_method = bubble_method + """\n  Future<void> _openBridgeGame() async {\n    final won = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => BridgeMathGamePage(soundOn: _soundOn, hapticOn: _hapticOn)));\n    if (won == true && !_bridgeGameDone) {\n      if (_hapticOn) await HapticFeedback.heavyImpact();\n      setState(() { _bridgeGameDate = _today; _stars += 10; _reactionTick++; });\n      await _persist();\n    }\n  }\n"""
once(bubble_method, bridge_method, 'open bridge')
once("      _bubbleGameDate = '';\n", "      _bubbleGameDate = '';\n      _bridgeGameDate = '';\n", 'reset')

once("        motiMinuteDone: _motiMinuteDone,\n        bubbleGameDone: _bubbleGameDone,\n        moodLocked: _moodLockedToday,\n", "        motiMinuteDone: _motiMinuteDone,\n        bubbleGameDone: _bubbleGameDone,\n        bridgeGameDone: _bridgeGameDone,\n        moodLocked: _moodLockedToday,\n", 'home args flags')
once("        onMotiMinute: _openMotiMinute,\n        onBubbleGame: _openBubbleGame,\n        onBreathe: _openBreathing,\n", "        onMotiMinute: _openMotiMinute,\n        onBubbleGame: _openBubbleGame,\n        onBridgeGame: _openBridgeGame,\n        onBreathe: _openBreathing,\n", 'home args callbacks')
once("    required this.motiMinuteDone,\n    required this.bubbleGameDone,\n    required this.moodLocked,\n", "    required this.motiMinuteDone,\n    required this.bubbleGameDone,\n    required this.bridgeGameDone,\n    required this.moodLocked,\n", 'ctor flag')
once("    required this.onMotiMinute,\n    required this.onBubbleGame,\n    required this.onBreathe,\n", "    required this.onMotiMinute,\n    required this.onBubbleGame,\n    required this.onBridgeGame,\n    required this.onBreathe,\n", 'ctor callback')
once("  final bool motiMinuteDone;\n  final bool bubbleGameDone;\n  final bool moodLocked;\n", "  final bool motiMinuteDone;\n  final bool bubbleGameDone;\n  final bool bridgeGameDone;\n  final bool moodLocked;\n", 'field flag')
once("  final Future<void> Function() onMotiMinute;\n  final Future<void> Function() onBubbleGame;\n  final Future<void> Function() onBreathe;\n", "  final Future<void> Function() onMotiMinute;\n  final Future<void> Function() onBubbleGame;\n  final Future<void> Function() onBridgeGame;\n  final Future<void> Function() onBreathe;\n", 'field callback')

card = """        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),\n            child: MotiGameCard(doneToday: bubbleGameDone, onStart: onBubbleGame),\n          ),\n        ),\n        const SliverToBoxAdapter(child: SizedBox(height: 28)),\n"""
card_new = """        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),\n            child: MotiGameCard(doneToday: bubbleGameDone, onStart: onBubbleGame),\n          ),\n        ),\n        SliverToBoxAdapter(\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),\n            child: MotiBridgeGameCard(doneToday: bridgeGameDone, onStart: onBridgeGame),\n          ),\n        ),\n        const SliverToBoxAdapter(child: SizedBox(height: 28)),\n"""
once(card, card_new, 'bridge card')

p.write_text(s)
print('v4.0 main integration applied')

# v4.4: patch the known-good v4.3 bridge source after it is decoded.
patch_file = Path(__file__).with_name('v44_patch.b64')
bridge_file = p.parent / 'moti_bridge_game.dart'
patch_bytes = gzip.decompress(base64.b64decode(patch_file.read_text().strip()))
tmp_patch = Path('/tmp/animo_v44.patch')
tmp_patch.write_bytes(patch_bytes)
subprocess.run(['patch', '-p5', '--batch', '--forward', '-i', str(tmp_patch)], cwd=bridge_file.parent, check=True)
print('v4.4 bridge damage + Moti sizing patch applied')
