from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text()
old='''  void _clockWarning() {\n    if (_questionRemaining <= 0 || _questionRemaining > 3 || _lastAlertSecond == _questionRemaining) return;\n    _lastAlertSecond = _questionRemaining;\n    if (_questionRemaining == 1) {\n      _playClock('reloj_alarma.wav', volume: .58);\n      if (widget.hapticOn) HapticFeedback.selectionClick();\n    } else {\n      _playClock('reloj_tick.wav', volume: .38);\n    }\n  }\n'''
new='''  void _clockWarning() {\n    if (_questionRemaining <= 0 || _lastAlertSecond == _questionRemaining) return;\n    _lastAlertSecond = _questionRemaining;\n    final danger = _questionRemaining <= 3;\n    _playClock('reloj_tick.wav', volume: danger ? .48 : .30);\n    if (_questionRemaining == 1) {\n      Future.delayed(const Duration(milliseconds: 150), () {\n        if (mounted && !_finished && !_transitioning) {\n          _play('reloj_alarma.wav', volume: .52);\n        }\n      });\n      if (widget.hapticOn) HapticFeedback.selectionClick();\n    }\n  }\n'''
if old not in s: raise SystemExit('clock function not found')
s=s.replace(old,new,1)
old2='''\n      if (_remaining <= 5 && _remaining > 0 && _questionRemaining > 3) {\n        _playClock('reloj_tick.wav', volume: .34);\n      }\n'''
if old2 not in s: raise SystemExit('global tick block not found')
s=s.replace(old2,'\n',1)
s=s.replace("await _play('moti_salto.wav', volume: .45);", "await _play('moti_salto_uju.wav', volume: .58);",1)
s=s.replace("Future.delayed(const Duration(milliseconds: 380), _finish);", "Future.delayed(const Duration(milliseconds: 760), _finish);",1)
s=s.replace("_play(won ? 'moti_meta.wav' : 'moti_fin.wav', volume: won ? .58 : .35);", "_play(won ? 'moti_festejo.wav' : 'moti_fin.wav', volume: won ? .72 : .35);",1)
p.write_text(s)
print('v3.9 audio patch applied')
